import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../database/hive_boxes.dart';
import '../outbox/outbox_local_data_source.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../../features/downtime/domain/models/downtime_log_model.dart';
import '../../../features/downtime/data/datasources/downtime_remote_data_source.dart';
import '../../../features/assets/domain/models/machine_model.dart';
import '../../../features/assets/data/datasources/machine_remote_data_source.dart';

/// Coordinates incremental pull synchronization (delta sync) using server timestamps.
class DeltaSyncCoordinator {
  final WorkOrderRemoteDataSource _workOrderRemote;
  final DowntimeRemoteDataSource _downtimeRemote;
  final MachineRemoteDataSource _machineRemote;
  final OutboxLocalDataSource _outboxLocal;

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

  Future<void> syncDeltas() async {
    final nowUtc = DateTime.now().toUtc();
    final rawCursor = _settingsBox.get('last_pull_timestamp') as String?;
    final cursor = rawCursor != null
        ? DateTime.parse(rawCursor)
        : nowUtc.subtract(const Duration(days: 30));

    debugPrint('📥 DeltaSyncCoordinator: pulling deltas modified after ${cursor.toIso8601String()}');

    try {
      await Future.wait([
        _syncWorkOrdersDelta(cursor),
        _syncDowntimeDelta(cursor),
        _syncMachinesDelta(cursor),
      ]);

      await _settingsBox.put('last_pull_timestamp', nowUtc.toIso8601String());
      debugPrint('✅ DeltaSyncCoordinator: deltas reconciled successfully');
    } catch (e) {
      debugPrint('⚠️ DeltaSyncCoordinator error during pull sync: $e');
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
      await box.put(remoteMachine.id, remoteMachine);
    }
  }
}
