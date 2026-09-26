import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/model_adapters.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_sync_engine.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/spare_part_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/hive_work_order_local_data_source.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/repositories/hive_work_order_repository.dart';
import 'helpers/fake_outbox_local_data_source.dart';
import 'outbox_sync_engine_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeOutboxLocalDataSource fakeOutbox;
  late RecordingWorkOrderRemoteDataSource mockRemote;
  late FakeDowntimeRemoteDataSource mockDowntime;
  late OutboxSyncEngine syncEngine;
  late HiveWorkOrderRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_handshake_e2e');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(WorkOrderTypeAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(WorkOrderStatusAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(PriorityAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(PlantShiftAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(EventChronologyAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SparePartModelAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(WorkOrderActivityLogAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(WorkOrderModelAdapter());

    await Hive.openBox<WorkOrderModel>(HiveBoxes.workOrdersBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).clear();
    fakeOutbox = FakeOutboxLocalDataSource();
    mockRemote = RecordingWorkOrderRemoteDataSource();
    mockDowntime = FakeDowntimeRemoteDataSource();

    syncEngine = OutboxSyncEngine(
      outboxLocal: fakeOutbox,
      workOrderRemote: mockRemote,
      downtimeRemote: mockDowntime,
    );

    repository = HiveWorkOrderRepository(
      localDataSource: HiveWorkOrderLocalDataSource(),
      syncEngine: syncEngine,
    );
  });

  test('5-step maintenance handshake executes end-to-end with immutable audit logs and outbox FIFO', () async {
    const woId = 'WO-HANDSHAKE-001';
    final operatorUser = MockUsers.drawingLead;
    final supervisorUser = MockUsers.maintenanceSupervisor;
    final technicianUser = MockUsers.mechanicalTech;

    // STEP 1: Operator reports breakdown
    final initialWo = WorkOrderModel(
      id: woId,
      title: 'Extruder Head Heating Coil Failure',
      description: 'Heater zone 3 is not reaching 220C target',
      machineId: 'EXT-01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.open,
      priority: Priority.high,
      createdAt: DateTime.now(),
    );

    final created = await repository.createWorkOrder(initialWo, caller: operatorUser);
    expect(created.status, WorkOrderStatus.open);
    expect(created.activityLogs.length, 1);
    expect(created.activityLogs.first.stepName, 'REPORTED');

    // STEP 2: Supervisor assigns technician
    await repository.assignTechnician(
      woId,
      technicianUser.id,
      supervisorUser.id,
      caller: supervisorUser,
    );
    var current = (await repository.getWorkOrderById(woId))!;
    expect(current.status, WorkOrderStatus.assigned);
    expect(current.assignedToTechnicianId, technicianUser.id);
    expect(current.activityLogs.length, 2);
    expect(current.activityLogs.last.stepName, 'ASSIGNED');

    // STEP 3: Technician starts repair
    await repository.startRepair(woId, caller: technicianUser);
    current = (await repository.getWorkOrderById(woId))!;
    expect(current.status, WorkOrderStatus.inProgress);
    expect(current.startedAt, isNotNull);
    expect(current.activityLogs.length, 3);
    expect(current.activityLogs.last.stepName, 'REPAIR_STARTED');

    // STEP 4A: Technician logs spare part replacement
    const replacementPart = SparePartModel(
      id: 'PART-001',
      partNumber: 'HEATER-COIL-4KW',
      name: 'Ceramic Band Heater 4kW',
      quantityUsed: 1,
      unitCost: 120.0,
    );
    await repository.addSparePart(woId, replacementPart, caller: technicianUser);
    current = (await repository.getWorkOrderById(woId))!;
    expect(current.spareParts.length, 1);
    expect(current.spareParts.first.partNumber, 'HEATER-COIL-4KW');
    expect(current.activityLogs.length, 4);

    // STEP 4B: Technician completes repair, awaiting test run
    await repository.completeWorkOrder(
      woId,
      rootCause: 'Ceramic insulation cracked causing ground short',
      actionsTaken: 'Replaced band heater and torqued terminal lugs',
      caller: technicianUser,
    );
    current = (await repository.getWorkOrderById(woId))!;
    expect(current.status, WorkOrderStatus.completed);
    expect(current.rootCause, contains('insulation cracked'));
    expect(current.activityLogs.length, 5);

    // STEP 5A: Operator confirms test run
    await repository.confirmTestRun(woId, caller: operatorUser);
    current = (await repository.getWorkOrderById(woId))!;
    expect(current.activityLogs.length, 6);
    expect(current.activityLogs.last.stepName, 'TEST_RUN_PASSED');

    // STEP 5B: Supervisor/Operator final approval & ticket closure
    await repository.approveAndClose(woId, caller: supervisorUser);
    current = (await repository.getWorkOrderById(woId))!;
    expect(current.status, WorkOrderStatus.verifiedClosed);
    expect(current.completedAt, isNotNull);
    expect(current.activityLogs.length, 7);
    expect(current.activityLogs.last.stepName, 'CLOSED');

    // VERIFY OUTBOX: All handshake transitions generated queued OutboxCommands
    final commands = await fakeOutbox.getCommandsForAggregate(woId);
    expect(commands.length, 7);
    expect(commands.map((c) => c.commandType).toList(), [
      'create_work_order',
      'assign_work_order',
      'start_work_order',
      'add_work_order_part',
      'complete_work_order',
      'confirm_test_run',
      'close_work_order',
    ]);
  });
}
