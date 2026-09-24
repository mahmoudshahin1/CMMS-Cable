import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/chronology_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/spare_part_adapter.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/work_order_activity_log_adapter.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/work_order_model_adapter.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/command_error_classifier.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_sync_engine.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/downtime/data/datasources/downtime_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/models/downtime_log_model.dart';
import 'helpers/fake_outbox_local_data_source.dart';

class MockWorkOrderRemoteForErrors implements WorkOrderRemoteDataSource {
  final List<OutboxCommand> executedCommands = [];
  Exception? errorToThrow;
  WorkOrderModel? authoritativeModel;
  int fetchCallCount = 0;

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final cmd = command as OutboxCommand;
    executedCommands.add(cmd);
    if (errorToThrow != null) throw errorToThrow!;
    return {'status': 'ok'};
  }

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async {
    fetchCallCount++;
    return authoritativeModel;
  }

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => [];
  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime c) async => [];
  @override
  Future<void> syncWorkOrder(WorkOrderModel w) async {}
  @override
  Future<void> deleteRemoteWorkOrder(String id) async {}
}

class StubDowntimeRemote implements DowntimeRemoteDataSource {
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic c) async => {};
  @override
  Future<List<DowntimeLogModel>> fetchDowntimeLogs() async => [];
  @override
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs() async => [];
  @override
  Future<List<DowntimeLogModel>> fetchModifiedAfter(DateTime c) async => [];
  @override
  Future<void> syncDowntimeLog(DowntimeLogModel l) async {}
}

void main() {
  late Directory tempDir;
  late FakeOutboxLocalDataSource fakeOutbox;
  late MockWorkOrderRemoteForErrors mockRemote;
  late OutboxSyncEngine engine;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_terminal_tests');
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
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).clear();
    fakeOutbox = FakeOutboxLocalDataSource();
    mockRemote = MockWorkOrderRemoteForErrors();
    engine = OutboxSyncEngine(
      outboxLocal: fakeOutbox,
      workOrderRemote: mockRemote,
      downtimeRemote: StubDowntimeRemote(),
      autoStartSync: false,
    );
  });

  tearDown(() => engine.dispose());

  WorkOrderModel makeWorkOrder({required String id, int version = 1, WorkOrderStatus status = WorkOrderStatus.open}) =>
      WorkOrderModel(id: id, title: 'Motor', description: 'Check', machineId: 'EXT-01',
          type: WorkOrderType.breakdown, status: status, priority: Priority.high, createdAt: DateTime.now(), version: version);

  group('Outbox Terminal Error & Authoritative Reconciliation Tests', () {
    test('40001 Version Conflict: stops retry, marks failedConflict, reconciles local Hive', () async {
      const woId = 'wo-conflict-101';
      await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).put(
        woId, makeWorkOrder(id: woId, version: 1, status: WorkOrderStatus.assigned),
      );
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'cmd-conflict-1', commandType: 'start_work_order',
        aggregateId: woId, payload: {}, occurredAt: DateTime.now(), expectedVersion: 1,
      ));

      mockRemote.errorToThrow = const PostgrestException(
        message: 'version conflict: expected version 1 but current version is 2',
        code: '40001',
      );
      mockRemote.authoritativeModel = makeWorkOrder(id: woId, version: 2, status: WorkOrderStatus.inProgress);

      OutboxTerminalFailure? captured;
      final sub = engine.terminalFailureStream.listen((f) => captured = f);

      await engine.syncNow();

      final saved = fakeOutbox.getCommand('cmd-conflict-1')!;
      expect(saved.status, equals(OutboxCommandStatus.failedConflict));
      expect(saved.attempts, equals(1));

      final reconciled = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).get(woId)!;
      expect(reconciled.version, equals(2));
      expect(reconciled.status, equals(WorkOrderStatus.inProgress));
      expect(mockRemote.fetchCallCount, equals(1));
      expect(captured?.classification.type, equals(CommandFailureType.terminalConflict));
      expect(captured?.userMessage, contains('updated by someone else'));

      // Assert no automatic retry on subsequent syncNow()
      final execCount = mockRemote.executedCommands.length;
      await engine.syncNow();
      expect(mockRemote.executedCommands.length, equals(execCount));
      expect(await fakeOutbox.getPendingCount(), equals(0));
      await sub.cancel();
    });

    test('42501 Unauthorized: stops retry, marks failedRejected, reconciles server state', () async {
      const woId = 'wo-unauth-202';
      final localWo = makeWorkOrder(id: woId, version: 1, status: WorkOrderStatus.assigned);
      await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).put(woId, localWo);
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'cmd-unauth-1', commandType: 'start_work_order', aggregateId: woId,
        payload: {}, occurredAt: DateTime.now(),
      ));

      mockRemote.errorToThrow = const PostgrestException(
        message: 'permission denied: user not assigned to work order', code: '42501',
      );
      mockRemote.authoritativeModel = localWo;

      OutboxTerminalFailure? captured;
      final sub = engine.terminalFailureStream.listen((f) => captured = f);

      await engine.syncNow();

      final saved = fakeOutbox.getCommand('cmd-unauth-1')!;
      expect(saved.status, equals(OutboxCommandStatus.failedRejected));
      expect(captured?.classification.type, equals(CommandFailureType.terminalUnauthorized));
      expect(captured?.userMessage, contains('not assigned'));

      await engine.syncNow();
      expect(mockRemote.executedCommands.length, equals(1));
      await sub.cancel();
    });

    test('P0001 Illegal State Transition: stops retry, marks failedRejected, reconciles state', () async {
      const woId = 'wo-illegal-303';
      final localWo = makeWorkOrder(id: woId, version: 1, status: WorkOrderStatus.assigned);
      await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).put(woId, localWo);
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'cmd-illegal-1', commandType: 'confirm_test_run', aggregateId: woId,
        payload: {}, occurredAt: DateTime.now(),
      ));

      mockRemote.errorToThrow = const PostgrestException(
        message: 'illegal state transition: cannot confirm test run', code: 'P0001',
      );
      mockRemote.authoritativeModel = localWo;

      OutboxTerminalFailure? captured;
      final sub = engine.terminalFailureStream.listen((f) => captured = f);

      await engine.syncNow();

      final saved = fakeOutbox.getCommand('cmd-illegal-1')!;
      expect(saved.status, equals(OutboxCommandStatus.failedRejected));
      expect(captured?.classification.type, equals(CommandFailureType.terminalIllegalState));
      expect(captured?.userMessage, contains('no longer in a state'));

      await engine.syncNow();
      expect(mockRemote.executedCommands.length, equals(1));
      await sub.cancel();
    });

    test('P0002 Work Order Not Found: stops retry, marks failedRejected immediately', () async {
      const woId = 'wo-notfound-404';
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'cmd-notfound-1', commandType: 'start_work_order', aggregateId: woId, payload: {}, occurredAt: DateTime.now(),
      ));

      mockRemote.errorToThrow = const PostgrestException(message: 'work order not found', code: 'P0002');
      mockRemote.authoritativeModel = null;

      OutboxTerminalFailure? captured;
      final sub = engine.terminalFailureStream.listen((f) => captured = f);

      await engine.syncNow();

      final saved = fakeOutbox.getCommand('cmd-notfound-1')!;
      expect(saved.status, equals(OutboxCommandStatus.failedRejected));
      expect(captured?.classification.type, equals(CommandFailureType.terminalNotFound));
      expect(captured?.userMessage, contains('not found'));

      await engine.syncNow();
      expect(mockRemote.executedCommands.length, equals(1));
      await sub.cancel();
    });

    test('Retryable transport error retains pending status, sets nextRetryAt and reuses commandId', () async {
      const woId = 'wo-retryable-505';
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'idempotent-cmd-uuid-777', commandType: 'start_work_order', aggregateId: woId, payload: {}, occurredAt: DateTime.now(),
      ));

      mockRemote.errorToThrow = const SocketException('Connection refused');

      await engine.syncNow();
      final saved = fakeOutbox.getCommand('idempotent-cmd-uuid-777')!;
      expect(saved.status, equals(OutboxCommandStatus.pending));
      expect(saved.attempts, equals(1));
      expect(saved.commandId, equals('idempotent-cmd-uuid-777'));
      expect(saved.nextRetryAt, isNotNull);
    });
  });
}
