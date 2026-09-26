import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_sync_engine.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/models/downtime_log_model.dart';
import 'package:orning_and_evening_remembrances/features/downtime/data/datasources/downtime_remote_data_source.dart';
import 'helpers/fake_outbox_local_data_source.dart';

class MockThrottledWorkOrderRemote implements WorkOrderRemoteDataSource {
  final List<OutboxCommand> executedCommands = [];
  Exception? throwException;

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final cmd = command as OutboxCommand;
    if (throwException != null) {
      throw throwException!;
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

class StubDowntimeRemote implements DowntimeRemoteDataSource {
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async => {};
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
  late MockThrottledWorkOrderRemote mockRemote;
  late OutboxSyncEngine engine;

  setUp(() {
    fakeOutbox = FakeOutboxLocalDataSource();
    mockRemote = MockThrottledWorkOrderRemote();
    engine = OutboxSyncEngine(
      outboxLocal: fakeOutbox,
      workOrderRemote: mockRemote,
      downtimeRemote: StubDowntimeRemote(),
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('Rate-Limiting Classification & Backoff Tests', () {
    test('detects PostgrestException P0429 as rate limited', () {
      const err = PostgrestException(
        message: 'RATE_LIMIT_EXCEEDED: Maximum 60 calls per minute exceeded.',
        code: 'P0429',
      );

      expect(engine.isRateLimited(err), isTrue);
      // Crucial: Must NEVER be classified as a permanent poison pill!
      expect(engine.isPermanentRejection(err), isFalse);
    });

    test('detects HTTP 429 status code as rate limited', () {
      const err = PostgrestException(
        message: 'Too Many Requests',
        code: '429',
      );

      expect(engine.isRateLimited(err), isTrue);
      expect(engine.isPermanentRejection(err), isFalse);
    });

    test('permanent errors are correctly marked as permanent and not rate-limited', () {
      const rlsViolation = PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );
      const customValidation = PostgrestException(
        message: 'INVALID_TRANSITION',
        code: 'P0001',
      );

      expect(engine.isRateLimited(rlsViolation), isFalse);
      expect(engine.isPermanentRejection(rlsViolation), isTrue);

      expect(engine.isRateLimited(customValidation), isFalse);
      expect(engine.isPermanentRejection(customValidation), isTrue);
    });

    test('calculates extended backoff (>= 30s) when rate-limited', () {
      for (var attempt = 0; attempt < 5; attempt++) {
        final backoff = engine.calculateBackoff(attempt, isRateLimited: true);
        expect(backoff, greaterThanOrEqualTo(30));
        expect(backoff, lessThanOrEqualTo(60));
      }
    });

    test('standard backoff starts small when not rate-limited', () {
      final backoff0 = engine.calculateBackoff(0, isRateLimited: false);
      expect(backoff0, lessThanOrEqualTo(4)); // 2^0 + max jitter 2 = 3
    });
  });

  group('Outbox Execution Throttling Resilience', () {
    test('does not move rate-limited command to dead-letter queue, leaves in outbox for retry', () async {
      final cmd = OutboxCommand(
        commandId: 'cmd-throttled-1',
        aggregateId: 'wo-rate-limit-1',
        commandType: 'start_repair_work_order',
        payload: {'version': 1},
        occurredAt: DateTime.now(),
      );
      await fakeOutbox.enqueue(cmd);

      // Simulate Supabase RPC rate-limiting (P0429)
      mockRemote.throwException = const PostgrestException(
        message: 'RATE_LIMIT_EXCEEDED: Rate limit of 60 requests reached.',
        code: 'P0429',
      );

      await engine.syncNow();

      // Verify command is marked failed (isDeadLetter: false)
      final pending = await fakeOutbox.getPendingCommands();
      expect(pending.length, equals(1));
      expect(pending.first.commandId, equals('cmd-throttled-1'));
      expect(pending.first.status, equals(OutboxCommandStatus.pending));
      expect(pending.first.attempts, equals(1));
      expect(pending.first.lastError, contains('RATE_LIMIT_EXCEEDED'));

      // Dead letter queue must be empty!
      final deadLetters = await fakeOutbox.getDeadLetterCommands();
      expect(deadLetters, isEmpty);

      // Next sync cycle: rate-limiting window passes
      mockRemote.throwException = null;
      await engine.syncNow();

      // Command successfully completes
      final finalPending = await fakeOutbox.getPendingCommands();
      expect(finalPending, isEmpty);
      expect(mockRemote.executedCommands.length, equals(1));
      expect(mockRemote.executedCommands.first.commandId, equals('cmd-throttled-1'));
    });
  });
}
