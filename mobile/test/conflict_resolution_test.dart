import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/model_adapters.dart';
import 'package:orning_and_evening_remembrances/core/sync/conflict/work_order_conflict_resolver.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_activity_log.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/spare_part_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';

class MockWorkOrderRemoteDataSource implements WorkOrderRemoteDataSource {
  WorkOrderModel? mockServerModel;

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async =>
      mockServerModel;

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => [];
  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime cursor) async => [];
  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {}
  @override
  Future<void> deleteRemoteWorkOrder(String id) async {}
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockWorkOrderRemoteDataSource mockRemote;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_conflict_test');
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
    mockRemote = MockWorkOrderRemoteDataSource();
    await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).clear();
  });

  test('Reconciles server authority with local uncommitted activity logs and parts', () async {
    final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
    final now = DateTime.now();

    final localLog = WorkOrderActivityLog(
      id: 'LOG-LOCAL-1',
      stepName: 'COMMENT',
      performedByName: 'Technician One',
      performedByEmail: 'tech1@cableops.local',
      performedByRole: 'TECHNICIAN',
      actionSummary: 'Local technician comment',
      recordedAt: now.subtract(const Duration(minutes: 5)),
    );

    final localPart = const SparePartModel(
      id: 'PART-LOCAL-1',
      partNumber: 'BEARING-6205',
      name: 'Deep Groove Ball Bearing',
      quantityUsed: 2,
      unitCost: 15.0,
    );

    final localModel = WorkOrderModel(
      id: 'WO-101',
      title: 'Motor Bearing Failure',
      description: 'Noise in motor',
      machineId: 'EXT-01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.inProgress,
      priority: Priority.high,
      createdAt: now.subtract(const Duration(hours: 1)),
      activityLogs: [localLog],
      spareParts: [localPart],
    );
    await box.put('WO-101', localModel);

    final serverLog = WorkOrderActivityLog(
      id: 'LOG-SERVER-1',
      stepName: 'PARTS_APPROVED',
      performedByName: 'Supervisor One',
      performedByEmail: 'sup1@cableops.local',
      performedByRole: 'SUPERVISOR',
      actionSummary: 'Supervisor approved parts request',
      recordedAt: now.subtract(const Duration(minutes: 10)),
    );

    final serverPart = const SparePartModel(
      id: 'PART-SERVER-1',
      partNumber: 'SEAL-OIL-45',
      name: 'Oil Seal 45mm',
      quantityUsed: 1,
      unitCost: 8.5,
    );

    mockRemote.mockServerModel = WorkOrderModel(
      id: 'WO-101',
      title: 'Motor Bearing Failure',
      description: 'Noise in motor (updated on server)',
      machineId: 'EXT-01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.completed,
      priority: Priority.high,
      createdAt: now.subtract(const Duration(hours: 1)),
      activityLogs: [serverLog],
      spareParts: [serverPart],
    );

    final reconciled = await WorkOrderConflictResolver.resolveVersionConflict(
      workOrderId: 'WO-101',
      remoteDataSource: mockRemote,
      localBox: box,
    );

    expect(reconciled, isNotNull);
    // Server status and description take authority
    expect(reconciled!.status, WorkOrderStatus.completed);
    expect(reconciled.description, 'Noise in motor (updated on server)');

    // Merged logs contain both server and local logs
    expect(reconciled.activityLogs.length, 2);
    expect(reconciled.activityLogs.map((l) => l.id),
        containsAll(['LOG-SERVER-1', 'LOG-LOCAL-1']));

    // Merged spare parts contain both server and local parts without duplicate
    expect(reconciled.spareParts.length, 2);
    expect(reconciled.spareParts.map((p) => p.partNumber),
        containsAll(['BEARING-6205', 'SEAL-OIL-45']));

    // Reconciled model is persisted to local Hive box
    final fromBox = box.get('WO-101');
    expect(fromBox?.status, WorkOrderStatus.completed);
    expect(fromBox?.activityLogs.length, 2);
  });

  test('Deduplicates identical activity logs and spare parts during reconciliation', () async {
    final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
    final now = DateTime.now();

    final sharedLog = WorkOrderActivityLog(
      id: 'LOG-SHARED',
      stepName: 'ACTION',
      performedByName: 'Technician One',
      performedByEmail: 'tech1@cableops.local',
      performedByRole: 'TECHNICIAN',
      actionSummary: 'Shared action',
      recordedAt: now,
    );

    final sharedPart = const SparePartModel(
      id: 'PART-SHARED',
      partNumber: 'FUSE-10A',
      name: '10A Fuse',
      quantityUsed: 1,
      unitCost: 2.0,
    );

    final localModel = WorkOrderModel(
      id: 'WO-102',
      title: 'Electrical Trip',
      description: 'Trip test',
      machineId: 'DR-02',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.open,
      priority: Priority.medium,
      createdAt: now,
      activityLogs: [sharedLog],
      spareParts: [sharedPart],
    );
    await box.put('WO-102', localModel);

    mockRemote.mockServerModel = localModel.copyWith(
      status: WorkOrderStatus.assigned,
    );

    final reconciled = await WorkOrderConflictResolver.resolveVersionConflict(
      workOrderId: 'WO-102',
      remoteDataSource: mockRemote,
      localBox: box,
    );

    expect(reconciled!.activityLogs.length, 1);
    expect(reconciled.spareParts.length, 1);
    expect(reconciled.status, WorkOrderStatus.assigned);
  });

  test('Returns null gracefully when work order is deleted on remote server', () async {
    final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
    mockRemote.mockServerModel = null;

    final result = await WorkOrderConflictResolver.resolveVersionConflict(
      workOrderId: 'WO-404',
      remoteDataSource: mockRemote,
      localBox: box,
    );

    expect(result, isNull);
  });
}
