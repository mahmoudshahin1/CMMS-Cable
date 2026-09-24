import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/hive_boxes.dart';
import 'command_error_classifier.dart';
import 'outbox_command.dart';
import 'outbox_local_data_source.dart';
import 'outbox_terminal_failure.dart';
import '../network/network_connectivity_checker.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../../features/downtime/data/datasources/downtime_remote_data_source.dart';

export 'outbox_terminal_failure.dart';

enum SyncEngineState { idle, syncing, offline, error }

/// Orchestrator for processing offline outbox mutations with FIFO ordering
/// per aggregate, jittered exponential backoff, and terminal error reconciliation.
class OutboxSyncEngine {
  final OutboxLocalDataSource _outboxLocal;
  final WorkOrderRemoteDataSource _workOrderRemote;
  final DowntimeRemoteDataSource _downtimeRemote;
  final NetworkConnectivityChecker? _networkChecker;

  final _stateController = StreamController<SyncEngineState>.broadcast();
  final _countController = StreamController<int>.broadcast();
  final _terminalFailureController =
      StreamController<OutboxTerminalFailure>.broadcast();

  bool _isSyncing = false;
  bool _needsResync = false;
  DateTime? _lastBackgroundSyncAt;
  final Random _random = Random();
  StreamSubscription<bool>? _netSub;
  Timer? _periodicTimer;

  OutboxSyncEngine({
    required OutboxLocalDataSource outboxLocal,
    required WorkOrderRemoteDataSource workOrderRemote,
    required DowntimeRemoteDataSource downtimeRemote,
    NetworkConnectivityChecker? networkChecker,
    Duration periodicInterval = const Duration(seconds: 15),
    bool autoStartSync = true,
  })  : _outboxLocal = outboxLocal,
        _workOrderRemote = workOrderRemote,
        _downtimeRemote = downtimeRemote,
        _networkChecker = networkChecker {
    _initConnectivityListener();
    _initPeriodicSync(periodicInterval);
    if (autoStartSync) unawaited(syncNow());
  }

  Stream<SyncEngineState> get stateStream => _stateController.stream;
  Stream<int> get pendingCountStream => _countController.stream;
  Stream<OutboxTerminalFailure> get terminalFailureStream =>
      _terminalFailureController.stream;

  void _initConnectivityListener() {
    _netSub = _networkChecker?.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        final now = DateTime.now();
        if (_lastBackgroundSyncAt != null &&
            now.difference(_lastBackgroundSyncAt!) < const Duration(seconds: 2)) {
          return;
        }
        _lastBackgroundSyncAt = now;
        debugPrint('🌐 Network restored: triggering OutboxSyncEngine');
        syncNow();
      }
    });
  }

  void _initPeriodicSync(Duration interval) {
    if (interval > Duration.zero) {
      _periodicTimer = Timer.periodic(interval, (_) {
        if (!_isSyncing) syncNow();
      });
    }
  }

  Future<void> enqueueAndTrigger(OutboxCommand command) async {
    await _outboxLocal.enqueue(command);
    await _updateCount();
    unawaited(syncNow());
  }

  Future<int> syncNow() async {
    if (_isSyncing) {
      _needsResync = true;
      return _outboxLocal.getPendingCount();
    }
    if (_networkChecker != null && !(await _networkChecker.isOnline)) {
      _stateController.add(SyncEngineState.offline);
      return _outboxLocal.getPendingCount();
    }
    try {
      if (Supabase.instance.client.auth.currentSession == null) {
        return await _outboxLocal.getPendingCount();
      }
    } catch (_) {}

    _isSyncing = true;
    _stateController.add(SyncEngineState.syncing);
    try {
      do {
        _needsResync = false;
        final pendingList = await _outboxLocal.getPendingCommands();
        if (pendingList.isEmpty) break;
        final grouped = <String, List<OutboxCommand>>{};
        for (final cmd in pendingList) {
          grouped.putIfAbsent(cmd.aggregateId, () => []).add(cmd);
        }
        for (final entry in grouped.entries) {
          await _processAggregateCommands(entry.value);
        }
      } while (_needsResync);
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
          cmd.status == OutboxCommandStatus.completed ||
          cmd.status == OutboxCommandStatus.failedConflict ||
          cmd.status == OutboxCommandStatus.failedRejected) {
        continue;
      }
      await _outboxLocal.markInFlight(cmd.commandId);
      try {
        await _dispatchCommand(cmd);
        await _outboxLocal.markCompleted(cmd.commandId);
        await _updateCount();
      } catch (e) {
        final errStr = e.toString();
        final classification = CommandErrorClassifier.classify(e);
        if (!classification.isRetryable) {
          debugPrint('🛑 Terminal rejection [${classification.type.name}] on ${cmd.commandId}: $errStr');
          await _outboxLocal.markTerminalFailure(
            cmd.commandId,
            errStr,
            status: classification.terminalStatus,
          );
          await _reconcileAggregate(cmd.aggregateId, cmd.commandType);
          _terminalFailureController.add(OutboxTerminalFailure(
            command: cmd,
            classification: classification,
            rawError: errStr,
          ));
          break;
        }
        if (cmd.attempts >= 10) {
          debugPrint('☠️ Max attempts reached on ${cmd.commandId}: $errStr');
          await _outboxLocal.markFailed(cmd.commandId, errStr, isDeadLetter: true);
        } else {
          final isRateLimit = classification.type == CommandFailureType.retryableRateLimit;
          final backoffSec = _calculateBackoff(cmd.attempts, isRateLimited: isRateLimit);
          final nextRetry = DateTime.now().add(Duration(seconds: backoffSec));
          debugPrint('⏳ Transient failure on ${cmd.commandId}: $errStr. Backoff: ${backoffSec}s');
          await _outboxLocal.markFailed(cmd.commandId, errStr, isDeadLetter: false, nextRetryAt: nextRetry);
        }
        break;
      }
    }
  }

  Future<void> _reconcileAggregate(String aggregateId, String commandType) async {
    if (commandType.endsWith('_work_order') ||
        commandType.endsWith('_part') ||
        commandType.contains('test_run')) {
      try {
        final authoritative = await _workOrderRemote.fetchWorkOrderById(aggregateId);
        if (authoritative != null && Hive.isBoxOpen(HiveBoxes.workOrdersBox)) {
          final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
          await box.put(authoritative.id, authoritative);
          debugPrint('🔄 Reconciled WorkOrder ${authoritative.id} to server version: ${authoritative.version}');
        }
      } catch (e) {
        debugPrint('⚠️ OutboxSyncEngine failed to reconcile aggregate $aggregateId: $e');
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
      throw ArgumentError('Unknown commandType: ${cmd.commandType}');
    }
  }

  bool isPermanentRejection(Object error) => CommandErrorClassifier.isTerminal(error);
  bool isRateLimited(Object error) => CommandErrorClassifier.isRateLimited(error);
  int calculateBackoff(int attempts, {bool isRateLimited = false}) =>
      _calculateBackoff(attempts, isRateLimited: isRateLimited);

  int _calculateBackoff(int attempts, {bool isRateLimited = false}) {
    if (isRateLimited) {
      final jitter = _random.nextInt(6);
      return min(60, 30 + (attempts * 5) + jitter);
    }
    final exp = min(5, attempts);
    final base = pow(2, exp).toInt();
    final jitter = _random.nextInt(3);
    return min(60, base + jitter);
  }

  Future<void> _updateCount() async {
    final count = await _outboxLocal.getPendingCount();
    _countController.add(count);
  }

  void dispose() {
    _periodicTimer?.cancel();
    _netSub?.cancel();
    _stateController.close();
    _countController.close();
    _terminalFailureController.close();
  }
}
