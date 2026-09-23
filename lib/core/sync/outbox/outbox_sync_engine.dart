import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'outbox_command.dart';
import 'outbox_local_data_source.dart';
import '../network/network_connectivity_checker.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../../features/downtime/data/datasources/downtime_remote_data_source.dart';

enum SyncEngineState { idle, syncing, offline, error }

/// Orchestrator for processing offline outbox mutations with FIFO ordering
/// per aggregate, jittered exponential backoff, and poison-pill isolation.
class OutboxSyncEngine {
  final OutboxLocalDataSource _outboxLocal;
  final WorkOrderRemoteDataSource _workOrderRemote;
  final DowntimeRemoteDataSource _downtimeRemote;
  final NetworkConnectivityChecker? _networkChecker;

  final _stateController = StreamController<SyncEngineState>.broadcast();
  final _countController = StreamController<int>.broadcast();

  bool _isSyncing = false;
  final Random _random = Random();
  StreamSubscription<bool>? _netSub;

  OutboxSyncEngine({
    required OutboxLocalDataSource outboxLocal,
    required WorkOrderRemoteDataSource workOrderRemote,
    required DowntimeRemoteDataSource downtimeRemote,
    NetworkConnectivityChecker? networkChecker,
  })  : _outboxLocal = outboxLocal,
        _workOrderRemote = workOrderRemote,
        _downtimeRemote = downtimeRemote,
        _networkChecker = networkChecker {
    _initConnectivityListener();
  }

  Stream<SyncEngineState> get stateStream => _stateController.stream;
  Stream<int> get pendingCountStream => _countController.stream;

  void _initConnectivityListener() {
    _netSub = _networkChecker?.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('🌐 Network restored: triggering OutboxSyncEngine');
        syncNow();
      }
    });
  }

  Future<void> enqueueAndTrigger(OutboxCommand command) async {
    await _outboxLocal.enqueue(command);
    await _updateCount();
    unawaited(syncNow());
  }

  Future<int> syncNow() async {
    if (_isSyncing) {
      return _outboxLocal.getPendingCount();
    }

    if (_networkChecker != null) {
      final online = await _networkChecker.isOnline;
      if (!online) {
        _stateController.add(SyncEngineState.offline);
        return _outboxLocal.getPendingCount();
      }
    }

    _isSyncing = true;
    _stateController.add(SyncEngineState.syncing);

    try {
      final pendingList = await _outboxLocal.getPendingCommands();
      final grouped = <String, List<OutboxCommand>>{};
      for (final cmd in pendingList) {
        grouped.putIfAbsent(cmd.aggregateId, () => []).add(cmd);
      }

      for (final entry in grouped.entries) {
        await _processAggregateCommands(entry.value);
      }

      _stateController.add(SyncEngineState.idle);
    } catch (e) {
      debugPrint('❌ OutboxSyncEngine unhandled sync error: $e');
      _stateController.add(SyncEngineState.error);
    } finally {
      _isSyncing = false;
      await _updateCount();
    }

    return _outboxLocal.getPendingCount();
  }

  Future<void> _processAggregateCommands(List<OutboxCommand> commands) async {
    for (final cmd in commands) {
      if (cmd.status == OutboxCommandStatus.deadLetter ||
          cmd.status == OutboxCommandStatus.completed) {
        continue;
      }

      await _outboxLocal.markInFlight(cmd.commandId);

      try {
        await _dispatchCommand(cmd);
        await _outboxLocal.markCompleted(cmd.commandId);
      } catch (e) {
        final errStr = e.toString();
        final isRateLimit = _isRateLimited(e);
        final isPoisonPill = _isPermanentRejection(e);

        if (isPoisonPill) {
          debugPrint('☠️ Poison pill detected on command ${cmd.commandId}: $errStr');
          await _outboxLocal.markFailed(cmd.commandId, errStr, isDeadLetter: true);
        } else {
          final backoffSec = _calculateBackoff(cmd.attempts, isRateLimited: isRateLimit);
          debugPrint('⏳ Transient failure on ${cmd.commandId}: $errStr. Backoff: ${backoffSec}s');
          await _outboxLocal.markFailed(cmd.commandId, errStr, isDeadLetter: false);
          break; // Stop further commands for this specific aggregate to preserve FIFO
        }
      }
    }
  }

  Future<void> _dispatchCommand(OutboxCommand cmd) async {
    if (cmd.commandType.endsWith('_work_order') ||
        cmd.commandType.endsWith('_part') ||
        cmd.commandType.contains('test_run')) {
      await _workOrderRemote.executeCommand(cmd);
    } else if (cmd.commandType.contains('downtime')) {
      await _downtimeRemote.executeCommand(cmd);
    } else {
      throw ArgumentError('Unknown commandType for dispatch: ${cmd.commandType}');
    }
  }

  bool isPermanentRejection(Object error) => _isPermanentRejection(error);
  bool isRateLimited(Object error) => _isRateLimited(error);
  int calculateBackoff(int attempts, {bool isRateLimited = false}) =>
      _calculateBackoff(attempts, isRateLimited: isRateLimited);

  bool _isRateLimited(Object error) {
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final msg = error.message.toUpperCase();
      if (code == 'P0429' || code == '429' || msg.contains('RATE_LIMIT')) {
        return true;
      }
    }
    final str = error.toString().toUpperCase();
    return str.contains('P0429') || str.contains('RATE_LIMIT') || str.contains('429');
  }

  bool _isPermanentRejection(Object error) {
    if (_isRateLimited(error)) {
      return false; // Throttling is transient, never a poison pill
    }

    if (error is PostgrestException) {
      final code = error.code ?? '';
      // 42501 (RLS violation), P0001 (Raise exception / validation), P0002 (Not found), 22P02 (Type syntax error), 23502 (Not null constraint)
      if (code == '42501' ||
          code == 'P0001' ||
          code == 'P0002' ||
          code == '22P02' ||
          code == '23502') {
        return true;
      }
      final msg = error.message.toUpperCase();
      if (msg.contains('UNAUTHORIZED') ||
          msg.contains('FORBIDDEN') ||
          msg.contains('CONFLICT') ||
          msg.contains('INVALID_TRANSITION') ||
          msg.contains('VERSION_MISMATCH')) {
        return true;
      }
    }

    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return false;
    }

    final str = error.toString().toUpperCase();
    if (str.contains('VERSION_MISMATCH') ||
        str.contains('UNAUTHORIZED') ||
        str.contains('NOT_FOUND') ||
        str.contains('INVALID_STATUS')) {
      return true;
    }

    return false;
  }

  int _calculateBackoff(int attempts, {bool isRateLimited = false}) {
    if (isRateLimited) {
      final jitter = _random.nextInt(10);
      return min(60, 30 + (attempts * 5) + jitter);
    }
    final exp = min(6, attempts);
    final base = pow(2, exp).toInt();
    final jitter = _random.nextInt(3);
    return min(60, base + jitter);
  }

  Future<void> _updateCount() async {
    final count = await _outboxLocal.getPendingCount();
    _countController.add(count);
  }

  void dispose() {
    _netSub?.cancel();
    _stateController.close();
    _countController.close();
  }
}
