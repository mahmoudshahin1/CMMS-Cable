import '../../domain/repositories/downtime_repository.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../domain/enums/downtime_category.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../datasources/downtime_local_data_source.dart';
import '../datasources/hive_downtime_local_data_source.dart';
import '../datasources/downtime_remote_data_source.dart';

/// Repository orchestrator for Downtime Logs.
///
/// Coordinates between [DowntimeLocalDataSource] (Hive cache)
/// and optional [DowntimeRemoteDataSource] (Supabase remote backend).
class HiveDowntimeRepository implements DowntimeRepository {
  final DowntimeLocalDataSource _localDataSource;
  final DowntimeRemoteDataSource? _remoteDataSource;

  HiveDowntimeRepository({
    DowntimeLocalDataSource? localDataSource,
    DowntimeRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? HiveDowntimeLocalDataSource(),
        _remoteDataSource = remoteDataSource;

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
