import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_sync_engine.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/models/downtime_log_model.dart';
import 'package:orning_and_evening_remembrances/features/downtime/data/datasources/downtime_remote_data_source.dart';
import 'helpers/fake_outbox_local_data_source.dart';

class RecordingWorkOrderRemoteDataSource implements WorkOrderRemoteDataSource {
  final List<OutboxCommand> executedCommands = [];
  Exception? throwOnCommand;
  String? failCommandId;

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final cmd = command as OutboxCommand;
    if (failCommandId == null || failCommandId == cmd.commandId) {
      if (throwOnCommand != null) {
        throw throwOnCommand!;
      }
    }
    executedCommands.add(cmd);
    return {'status': 'success', 'id': cmd.aggregateId};
  }

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => [];

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async => null;

  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime cursor) async => [];

  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {}

  @override
  Future<void> deleteRemoteWorkOrder(String id) async {}
}

class FakeDowntimeRemoteDataSource implements DowntimeRemoteDataSource {
  final List<OutboxCommand> executedCommands = [];

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final cmd = command as OutboxCommand;
    executedCommands.add(cmd);
    return {'status': 'success'};
  }

  @override
  Future<List<DowntimeLogModel>> fetchDowntimeLogs() async => [];

  @override
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs() async => [];

  @override
  Future<List<DowntimeLogModel>> fetchModifiedAfter(DateTime cursor) async => [];

  @override
  Future<void> syncDowntimeLog(DowntimeLogModel log) async {}
}

void main() {
  late FakeOutboxLocalDataSource fakeOutbox;
  late RecordingWorkOrderRemoteDataSource mockWorkOrderRemote;
  late FakeDowntimeRemoteDataSource mockDowntimeRemote;
  late OutboxSyncEngine engine;

  setUp(() {
    fakeOutbox = FakeOutboxLocalDataSource();
    mockWorkOrderRemote = RecordingWorkOrderRemoteDataSource();
    mockDowntimeRemote = FakeDowntimeRemoteDataSource();
    engine = OutboxSyncEngine(
      outboxLocal: fakeOutbox,
      workOrderRemote: mockWorkOrderRemote,
      downtimeRemote: mockDowntimeRemote,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  test('FIFO per aggregate: executes commands in chronological order', () async {
    final now = DateTime.now();
    final cmd1 = OutboxCommand(
      commandId: 'cmd-001',
      commandType: 'create_work_order',
      aggregateId: 'WO-100',
      payload: {'title': 'First'},
      occurredAt: now.subtract(const Duration(minutes: 10)),
    );
    final cmd2 = OutboxCommand(
      commandId: 'cmd-002',
      commandType: 'assign_work_order',
      aggregateId: 'WO-100',
      payload: {'technician_id': 'tech-1'},
      occurredAt: now.subtract(const Duration(minutes: 5)),
    );
    final cmd3 = OutboxCommand(
      commandId: 'cmd-003',
      commandType: 'create_work_order',
      aggregateId: 'WO-200',
      payload: {'title': 'Unrelated Ticket'},
      occurredAt: now.subtract(const Duration(minutes: 2)),
    );

    await fakeOutbox.enqueue(cmd2); // Enqueue out-of-order
    await fakeOutbox.enqueue(cmd1);
    await fakeOutbox.enqueue(cmd3);

    await engine.syncNow();

    expect(mockWorkOrderRemote.executedCommands.length, equals(3));
    expect(mockWorkOrderRemote.executedCommands[0].commandId, equals('cmd-001'));
    expect(mockWorkOrderRemote.executedCommands[1].commandId, equals('cmd-002'));
    expect(mockWorkOrderRemote.executedCommands[2].commandId, equals('cmd-003'));

    expect(fakeOutbox.getCommand('cmd-001')!.status, equals(OutboxCommandStatus.completed));
    expect(fakeOutbox.getCommand('cmd-002')!.status, equals(OutboxCommandStatus.completed));
    expect(fakeOutbox.getCommand('cmd-003')!.status, equals(OutboxCommandStatus.completed));
  });

  test('Transient failure preserves FIFO for failing aggregate but allows other aggregates to process', () async {
    final now = DateTime.now();
    final cmdA1 = OutboxCommand(
      commandId: 'cmd-A1',
      commandType: 'create_work_order',
      aggregateId: 'WO-A',
      payload: {},
      occurredAt: now.subtract(const Duration(minutes: 10)),
    );
    final cmdA2 = OutboxCommand(
      commandId: 'cmd-A2',
      commandType: 'assign_work_order',
      aggregateId: 'WO-A',
      payload: {},
      occurredAt: now.subtract(const Duration(minutes: 5)),
    );
    final cmdB = OutboxCommand(
      commandId: 'cmd-B',
      commandType: 'create_work_order',
      aggregateId: 'WO-B',
      payload: {},
      occurredAt: now.subtract(const Duration(minutes: 2)),
    );

    mockWorkOrderRemote.failCommandId = 'cmd-A1';
    mockWorkOrderRemote.throwOnCommand = const SocketException('Network unreachable');

    await fakeOutbox.enqueue(cmdA1);
    await fakeOutbox.enqueue(cmdA2);
    await fakeOutbox.enqueue(cmdB);

    await engine.syncNow();

    // cmd-A1 should fail retryably
    final savedA1 = fakeOutbox.getCommand('cmd-A1')!;
    expect(savedA1.status, equals(OutboxCommandStatus.pending));
    expect(savedA1.attempts, equals(1));

    // cmd-A2 should NOT have been attempted (FIFO preservation on failing aggregate)
    final savedA2 = fakeOutbox.getCommand('cmd-A2')!;
    expect(savedA2.status, equals(OutboxCommandStatus.pending));
    expect(savedA2.attempts, equals(0));

    // cmd-B belongs to another aggregate and should complete successfully!
    final savedB = fakeOutbox.getCommand('cmd-B')!;
    expect(savedB.status, equals(OutboxCommandStatus.completed));
  });

  test('Poison pill isolation marks command deadLetter and does NOT halt other commands', () async {
    final now = DateTime.now();
    final poisonCmd = OutboxCommand(
      commandId: 'cmd-poison',
      commandType: 'complete_work_order',
      aggregateId: 'WO-POISON',
      payload: {},
      occurredAt: now.subtract(const Duration(minutes: 10)),
    );
    final validCmd = OutboxCommand(
      commandId: 'cmd-valid',
      commandType: 'create_work_order',
      aggregateId: 'WO-VALID',
      payload: {},
      occurredAt: now.subtract(const Duration(minutes: 5)),
    );

    mockWorkOrderRemote.failCommandId = 'cmd-poison';
    mockWorkOrderRemote.throwOnCommand = const PostgrestException(
      message: 'VERSION_MISMATCH: Work order was modified by supervisor',
      code: 'P0001',
    );

    await fakeOutbox.enqueue(poisonCmd);
    await fakeOutbox.enqueue(validCmd);

    await engine.syncNow();

    final savedPoison = fakeOutbox.getCommand('cmd-poison')!;
    expect(
      savedPoison.status == OutboxCommandStatus.failedConflict ||
          savedPoison.status == OutboxCommandStatus.deadLetter,
      isTrue,
    );
    expect(savedPoison.lastError, contains('VERSION_MISMATCH'));

    final savedValid = fakeOutbox.getCommand('cmd-valid')!;
    expect(savedValid.status, equals(OutboxCommandStatus.completed));
  });

  test('Idempotency preservation: UUID commandId is preserved on retry', () async {
    final cmd = OutboxCommand(
      commandId: 'durable-uuid-v4-001',
      commandType: 'create_work_order',
      aggregateId: 'WO-RETRY',
      payload: {'data': 1},
      occurredAt: DateTime.now(),
    );

    mockWorkOrderRemote.throwOnCommand = const SocketException('Temporary timeout');
    await fakeOutbox.enqueue(cmd);
    await engine.syncNow();

    expect(fakeOutbox.getCommand('durable-uuid-v4-001')!.commandId, equals('durable-uuid-v4-001'));
    expect(fakeOutbox.getCommand('durable-uuid-v4-001')!.attempts, equals(1));

    // Second attempt recovers
    mockWorkOrderRemote.throwOnCommand = null;
    await engine.syncNow();

    expect(fakeOutbox.getCommand('durable-uuid-v4-001')!.status, equals(OutboxCommandStatus.completed));
    expect(mockWorkOrderRemote.executedCommands.last.commandId, equals('durable-uuid-v4-001'));
  });

  test('Self-draining loop: commands enqueued while sync is running are automatically drained', () async {
    final now = DateTime.now();
    final cmd1 = OutboxCommand(
      commandId: 'cmd-drain-1',
      commandType: 'create_work_order',
      aggregateId: 'WO-DRAIN-1',
      payload: {},
      occurredAt: now,
    );
    final cmd2 = OutboxCommand(
      commandId: 'cmd-drain-2',
      commandType: 'create_work_order',
      aggregateId: 'WO-DRAIN-2',
      payload: {},
      occurredAt: now.add(const Duration(seconds: 1)),
    );

    await fakeOutbox.enqueue(cmd1);

    // When cmd1 is dispatched, enqueue cmd2 and call enqueueAndTrigger to simulate re-entrancy
    mockWorkOrderRemote.executedCommands.clear();
    // Start syncing cmd1
    final syncFuture = engine.syncNow();

    // Enqueue cmd2 and trigger while sync is in progress
    await engine.enqueueAndTrigger(cmd2);

    await syncFuture;

    // Both cmd1 and cmd2 should be completed because the self-draining loop picked up cmd2!
    expect(mockWorkOrderRemote.executedCommands.length, equals(2));
    expect(fakeOutbox.getCommand('cmd-drain-1')!.status, equals(OutboxCommandStatus.completed));
    expect(fakeOutbox.getCommand('cmd-drain-2')!.status, equals(OutboxCommandStatus.completed));
  });
}
