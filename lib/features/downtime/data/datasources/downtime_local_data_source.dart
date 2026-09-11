import '../../domain/models/downtime_log_model.dart';

/// Abstract contract for downtime log local persistence (Hive).
///
/// Implementations handle CRUD operations against the local cache.
abstract class DowntimeLocalDataSource {
  /// Returns all cached downtime logs.
  Future<List<DowntimeLogModel>> getAllDowntimeLogs();

  /// Returns a single downtime log by [id], or null if not found.
  Future<DowntimeLogModel?> getDowntimeLogById(String id);

  /// Returns active (ongoing) downtime logs where endTime is null.
  Future<List<DowntimeLogModel>> getActiveDowntimeLogs();

  /// Returns downtime logs for a specific [machineId].
  Future<List<DowntimeLogModel>> getDowntimeLogsForMachine(String machineId);

  /// Persists a [downtimeLog] to the local cache. Upserts by ID.
  Future<void> cacheDowntimeLog(DowntimeLogModel downtimeLog);

  /// Persists a batch of downtime logs to the local cache.
  Future<void> cacheDowntimeLogs(List<DowntimeLogModel> logs);

  /// Updates a single downtime log in the local cache.
  Future<void> updateDowntimeLog(DowntimeLogModel downtimeLog);

  /// Deletes a downtime log from the local cache by [id].
  Future<void> deleteDowntimeLog(String id);
}
