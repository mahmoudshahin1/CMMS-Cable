import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/hive_boxes.dart';
import '../models/sync_status.dart';
import '../outbox/outbox_local_data_source.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../../features/downtime/domain/models/downtime_log_model.dart';
import '../../../features/downtime/data/datasources/downtime_remote_data_source.dart';
import '../../../features/assets/domain/models/machine_model.dart';
import '../../../features/assets/data/datasources/machine_remote_data_source.dart';

/// Coordinates incremental and full pull synchronization using server timestamps,
/// with defense-in-depth auth checking and optimistic local state protection.
class DeltaSyncCoordinator {
  final WorkOrderRemoteDataSource _workOrderRemote;
  final DowntimeRemoteDataSource _downtimeRemote;
  final MachineRemoteDataSource _machineRemote;
  final OutboxLocalDataSource _outboxLocal;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = const SyncStatus();

  DeltaSyncCoordinator({
    required WorkOrderRemoteDataSource workOrderRemote,
    required DowntimeRemoteDataSource downtimeRemote,
    required MachineRemoteDataSource machineRemote,
    required OutboxLocalDataSource outboxLocal,
  })  : _workOrderRemote = workOrderRemote,
        _downtimeRemote = downtimeRemote,
        _machineRemote = machineRemote,
        _outboxLocal = outboxLocal;

  Box get _settingsBox => Hive.box(HiveBoxes.settingsBox);

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  void _emitStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  bool _hasActiveAuthSession() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// Initial or full synchronization. Fetches complete sets if cursor is empty
  /// or when [forceFull] is true.
  Future<void> initialSync({bool forceFull = false}) async {
    if (!_hasActiveAuthSession()) {
      debugPrint('🛡️ DeltaSyncCoordinator: skipping initialSync (no active auth session)');
      return;
    }

    final pendingCount = await _outboxLocal.getPendingCount();
    _emitStatus(_currentStatus.copyWith(
      state: SyncState.syncing,
      isInitialSync: true,
      pendingOutboxCount: pendingCount,
      message: 'جاري مزامنة بيانات المصنع...',
    ));

    final rawCursor = _settingsBox.get('last_pull_timestamp') as String?;
    final isFirstRun = rawCursor == null || forceFull;

    try {
      if (isFirstRun) {
        debugPrint('📥 DeltaSyncCoordinator: running full initial sync from Supabase');
        await Future.wait([
          _fullSyncMachines(),
          _fullSyncWorkOrders(),
          _syncDowntimeDelta(DateTime.now().toUtc().subtract(const Duration(days: 60))),
        ]).timeout(const Duration(seconds: 8));
      } else {
        final cursor = DateTime.parse(rawCursor);
        await Future.wait([
          _syncWorkOrdersDelta(cursor),
          _syncDowntimeDelta(cursor),
          _syncMachinesDelta(cursor),
        ]).timeout(const Duration(seconds: 8));
      }

      final nowUtc = DateTime.now().toUtc();
      await _settingsBox.put('last_pull_timestamp', nowUtc.toIso8601String());

      _emitStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSyncedAt: nowUtc,
        isInitialSync: false,
        message: 'تمت المزامنة بنجاح',
      ));
      debugPrint('✅ DeltaSyncCoordinator: initialSync completed successfully');
    } catch (e) {
      debugPrint('⚠️ DeltaSyncCoordinator error during initialSync: $e');
      _emitStatus(_currentStatus.copyWith(
        state: SyncState.error,
        isInitialSync: false,
        message: 'فشلت المزامنة: $e',
      ));
    }
  }

  /// Incremental pull sync using server timestamp cursor.
  Future<void> syncDeltas() async {
    if (!_hasActiveAuthSession()) {
      debugPrint('🛡️ DeltaSyncCoordinator: skipping syncDeltas (no active auth session)');
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final rawCursor = _settingsBox.get('last_pull_timestamp') as String?;

    if (rawCursor == null) {
      return initialSync(forceFull: true);
    }

    final cursor = DateTime.parse(rawCursor);
    final pendingCount = await _outboxLocal.getPendingCount();

    _emitStatus(_currentStatus.copyWith(
      state: SyncState.syncing,
      pendingOutboxCount: pendingCount,
      message: 'جاري تحديث البيانات...',
    ));

    debugPrint('📥 DeltaSyncCoordinator: pulling deltas modified after ${cursor.toIso8601String()}');

    try {
      await Future.wait([
        _syncWorkOrdersDelta(cursor),
        _syncDowntimeDelta(cursor),
        _syncMachinesDelta(cursor),
      ]).timeout(const Duration(seconds: 8));

      await _settingsBox.put('last_pull_timestamp', nowUtc.toIso8601String());

      _emitStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSyncedAt: nowUtc,
        message: 'تم التحديث بنجاح',
      ));
      debugPrint('✅ DeltaSyncCoordinator: deltas reconciled successfully');
    } catch (e) {
      debugPrint('⚠️ DeltaSyncCoordinator error during pull sync: $e');
      _emitStatus(_currentStatus.copyWith(
        state: SyncState.error,
        message: 'خطأ أثناء المزامنة: $e',
      ));
    }
  }

  Future<void> _fullSyncMachines() async {
    final remoteMachines = await _machineRemote.fetchMachines();
    if (remoteMachines.isEmpty) return;

    final box = Hive.box<MachineModel>(HiveBoxes.machinesBox);
    for (final remoteMachine in remoteMachines) {
      final hasDirtyLocal =
          await _outboxLocal.hasPendingForAggregate(remoteMachine.id);
      if (hasDirtyLocal) {
        debugPrint('🛡️ Preserving optimistic local state for Machine ${remoteMachine.id}');
        continue;
      }
      await box.put(remoteMachine.id, remoteMachine);
    }
  }

  Future<void> _fullSyncWorkOrders() async {
    final remoteOrders = await _workOrderRemote.fetchWorkOrders();
    if (remoteOrders.isEmpty) return;

    final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
    for (final remoteWo in remoteOrders) {
      final hasDirtyLocal =
          await _outboxLocal.hasPendingForAggregate(remoteWo.id);
      if (hasDirtyLocal) {
        debugPrint('🛡️ Preserving optimistic local state for WorkOrder ${remoteWo.id}');
        continue;
      }
      await box.put(remoteWo.id, remoteWo);
    }
  }

  Future<void> _syncWorkOrdersDelta(DateTime cursor) async {
    final deltas = await _workOrderRemote.fetchModifiedAfter(cursor);
    if (deltas.isEmpty) return;

    final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
    for (final remoteWo in deltas) {
      final hasDirtyLocal =
          await _outboxLocal.hasPendingForAggregate(remoteWo.id);
      if (hasDirtyLocal) {
        debugPrint('🛡️ Preserving optimistic local state for WorkOrder ${remoteWo.id}');
        continue;
      }
      await box.put(remoteWo.id, remoteWo);
    }
  }

  Future<void> _syncDowntimeDelta(DateTime cursor) async {
    final deltas = await _downtimeRemote.fetchModifiedAfter(cursor);
    if (deltas.isEmpty) return;

    final box = Hive.box<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);
    for (final remoteLog in deltas) {
      final hasDirtyLocal =
          await _outboxLocal.hasPendingForAggregate(remoteLog.id);
      if (hasDirtyLocal) {
        debugPrint('🛡️ Preserving optimistic local state for Downtime ${remoteLog.id}');
        continue;
      }
      await box.put(remoteLog.id, remoteLog);
    }
  }

  Future<void> _syncMachinesDelta(DateTime cursor) async {
    final deltas = await _machineRemote.fetchModifiedAfter(cursor);
    if (deltas.isEmpty) return;

    final box = Hive.box<MachineModel>(HiveBoxes.machinesBox);
    for (final remoteMachine in deltas) {
      final hasDirtyLocal =
          await _outboxLocal.hasPendingForAggregate(remoteMachine.id);
      if (hasDirtyLocal) {
        debugPrint('🛡️ Preserving optimistic local state for Machine ${remoteMachine.id}');
        continue;
      }
      await box.put(remoteMachine.id, remoteMachine);
    }
  }

  void dispose() {
    _statusController.close();
  }
}
