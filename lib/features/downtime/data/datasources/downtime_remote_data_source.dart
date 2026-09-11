import '../../domain/models/downtime_log_model.dart';

/// Abstract contract for remote downtime operations (e.g. Supabase).
abstract class DowntimeRemoteDataSource {
  /// Fetches all downtime logs from the remote database.
  Future<List<DowntimeLogModel>> fetchDowntimeLogs();

  /// Fetches active downtime logs from the remote database.
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs();

  /// Pushes a created or updated downtime log to the remote database.
  Future<void> syncDowntimeLog(DowntimeLogModel log);
}

/// Offline-first fallback / stub for [DowntimeRemoteDataSource].
class SupabaseDowntimeRemoteDataSourceStub implements DowntimeRemoteDataSource {
  const SupabaseDowntimeRemoteDataSourceStub();

  @override
  Future<List<DowntimeLogModel>> fetchDowntimeLogs() async => const [];

  @override
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs() async => const [];

  @override
  Future<void> syncDowntimeLog(DowntimeLogModel log) async {
    // Queued for background sync when online
  }
}
