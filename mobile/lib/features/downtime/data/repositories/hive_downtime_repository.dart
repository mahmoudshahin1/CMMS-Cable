import '../../domain/repositories/downtime_repository.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../domain/enums/downtime_category.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';
import '../datasources/downtime_local_data_source.dart';
import '../datasources/hive_downtime_local_data_source.dart';
import '../datasources/downtime_remote_data_source.dart';
import '../datasources/downtime_outbox_factory.dart';

/// Repository orchestrator for Downtime Logs.
///
/// Coordinates between [DowntimeLocalDataSource] (Hive cache)
/// and optional [DowntimeRemoteDataSource] (Supabase remote backend).
class HiveDowntimeRepository implements DowntimeRepository {
  final DowntimeLocalDataSource _localDataSource;
  final DowntimeRemoteDataSource? _remoteDataSource;
  final OutboxSyncEngine? _syncEngine;

  HiveDowntimeRepository({
    DowntimeLocalDataSource? localDataSource,
    DowntimeRemoteDataSource? remoteDataSource,
    OutboxSyncEngine? syncEngine,
  })  : _localDataSource = localDataSource ?? HiveDowntimeLocalDataSource(),
        _remoteDataSource = remoteDataSource,
        _syncEngine = syncEngine;

  @override
  Future<List<DowntimeLogModel>> getAllDowntimeLogs() async {
    return _localDataSource.getAllDowntimeLogs();
  }

  @override
  Future<List<DowntimeLogModel>> getActiveDowntimeLogs() async {
    return _localDataSource.getActiveDowntimeLogs();
  }

  @override
  Future<List<DowntimeLogModel>> getDowntimeLogsForMachine(
      String machineId) async {
    return _localDataSource.getDowntimeLogsForMachine(machineId);
  }

  @override
  Future<DowntimeLogModel> createDowntimeLog(DowntimeLogModel log) async {
    final startChrono =
        log.startChronology ?? EventChronology.fromDateTime(log.startTime);
    final withChrono = log.copyWith(
      startTime: startChrono.recordedAtUtc,
      startChronology: startChrono,
    );
    await _localDataSource.cacheDowntimeLog(withChrono);
    _remoteDataSource?.syncDowntimeLog(withChrono);
    _syncEngine?.enqueueAndTrigger(DowntimeOutboxFactory.create(withChrono));
    return withChrono;
  }

  @override
  Future<void> endDowntime(String logId, {String? comments}) async {
    final log = await _localDataSource.getDowntimeLogById(logId);
    if (log != null) {
      final endChrono = EventChronology.now();
      final updated = log.copyWith(
        endTime: endChrono.recordedAtUtc,
        endChronology: endChrono,
        comments: comments ?? log.comments,
      );
      await _localDataSource.updateDowntimeLog(updated);
      _remoteDataSource?.syncDowntimeLog(updated);
      _syncEngine?.enqueueAndTrigger(DowntimeOutboxFactory.close(updated));
    }
  }

  @override
  Future<void> updateCategory(
      String logId, DowntimeCategory newCategory) async {
    final log = await _localDataSource.getDowntimeLogById(logId);
    if (log != null) {
      final updated = log.copyWith(category: newCategory);
      await _localDataSource.updateDowntimeLog(updated);
      _remoteDataSource?.syncDowntimeLog(updated);
    }
  }

  @override
  Future<void> attachWorkOrder(String logId, String workOrderId) async {
    final log = await _localDataSource.getDowntimeLogById(logId);
    if (log != null) {
      final updated = log.copyWith(workOrderId: workOrderId);
      await _localDataSource.updateDowntimeLog(updated);
      _remoteDataSource?.syncDowntimeLog(updated);
    }
  }
}
