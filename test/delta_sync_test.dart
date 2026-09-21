import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/model_adapters.dart';
import 'package:orning_and_evening_remembrances/core/sync/delta/delta_sync_coordinator.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/models/downtime_log_model.dart';
import 'package:orning_and_evening_remembrances/features/downtime/data/datasources/downtime_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/data/datasources/machine_remote_data_source.dart';
import 'helpers/fake_outbox_local_data_source.dart';

class StubWorkOrderRemote implements WorkOrderRemoteDataSource {
  final List<WorkOrderModel> remoteDeltas;
  DateTime? capturedCursor;

  StubWorkOrderRemote({this.remoteDeltas = const []});

  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime cursor) async {
    capturedCursor = cursor;
    return remoteDeltas;
  }

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => remoteDeltas;
  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async => null;
  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {}
  @override
  Future<void> deleteRemoteWorkOrder(String id) async {}
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async => {};
}

class StubDowntimeRemote implements DowntimeRemoteDataSource {
  @override
  Future<List<DowntimeLogModel>> fetchDowntimeLogs() async => [];
  @override
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs() async => [];
  @override
  Future<List<DowntimeLogModel>> fetchModifiedAfter(DateTime cursor) async => [];
  @override
  Future<void> syncDowntimeLog(DowntimeLogModel log) async {}
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async => {};
}

class StubMachineRemote implements MachineRemoteDataSource {
  @override
  Future<List<MachineModel>> fetchMachines() async => [];
  @override
  Future<MachineModel?> fetchMachineById(String id) async => null;
  @override
  Future<List<MachineModel>> fetchModifiedAfter(DateTime cursor) async => [];
  @override
  Future<void> syncMachine(MachineModel machine) async {}
  @override
  Future<void> syncProcessLog(dynamic log) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOutboxLocalDataSource fakeOutbox;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_delta_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(WorkOrderTypeAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(WorkOrderStatusAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(PriorityAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(PlantShiftAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(EventChronologyAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SparePartModelAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(WorkOrderActivityLogAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(WorkOrderModelAdapter());

    await Hive.openBox(HiveBoxes.settingsBox);
    await Hive.openBox<WorkOrderModel>(HiveBoxes.workOrdersBox);
    await Hive.openBox<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);
    await Hive.openBox<MachineModel>(HiveBoxes.machinesBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    fakeOutbox = FakeOutboxLocalDataSource();
  });

  test('DeltaSyncCoordinator skips overwriting locally dirty work orders', () async {
    final localBox = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);

    final localWo = WorkOrderModel(
      id: 'WO-LOCAL-DIRTY',
      title: 'Local Optimistic Edit',
      description: 'Local desc',
      machineId: 'DR01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.inProgress,
      priority: Priority.high,
      createdAt: DateTime.now(),
    );

    // Enqueue a pending command for this work order
    await fakeOutbox.enqueue(OutboxCommand(
      commandId: 'cmd-dirty',
      commandType: 'start_work_order',
      aggregateId: 'WO-LOCAL-DIRTY',
      payload: {},
      occurredAt: DateTime.now(),
    ));

    final remoteWo = localWo.copyWith(
      title: 'Server Stale Title',
      status: WorkOrderStatus.assigned, // Stale state from server
    );

    final woRemote = StubWorkOrderRemote(remoteDeltas: [remoteWo]);
    final coordinator = DeltaSyncCoordinator(
      workOrderRemote: woRemote,
      downtimeRemote: StubDowntimeRemote(),
      machineRemote: StubMachineRemote(),
      outboxLocal: fakeOutbox,
    );

    // Pre-insert local optimistic model
    await localBox.put('WO-LOCAL-DIRTY', localWo);

    await coordinator.syncDeltas();

    // The local box MUST retain the optimistic local version, not the server stale state!
    final result = localBox.get('WO-LOCAL-DIRTY');
    expect(result!.title, equals('Local Optimistic Edit'));
    expect(result.status, equals(WorkOrderStatus.inProgress));
  });
}
