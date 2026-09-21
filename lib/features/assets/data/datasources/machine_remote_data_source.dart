import '../../domain/models/machine_model.dart';
import '../../domain/models/process_log_model.dart';

/// Abstract contract for machine and process log remote operations (e.g. Supabase).
///
/// Implementations handle remote queries and mutations when network is available.
abstract class MachineRemoteDataSource {
  /// Fetches all machines from the remote database.
  Future<List<MachineModel>> fetchMachines();

  /// Fetches a single machine by [id] from the remote database.
  Future<MachineModel?> fetchMachineById(String id);

  /// Pushes a machine state update to the remote database.
  Future<void> syncMachine(MachineModel machine);

  /// Pushes a process log to the remote database.
  Future<void> syncProcessLog(ProcessLogModel log);

  /// Fetches machines modified after [cursor] for delta sync.
  Future<List<MachineModel>> fetchModifiedAfter(DateTime cursor);
}

/// Offline-first fallback / stub for [MachineRemoteDataSource].
///
/// In offline mode, mutations are queued or safely ignored until
/// live Supabase credentials and network connectivity are established.
class SupabaseMachineRemoteDataSourceStub implements MachineRemoteDataSource {
  const SupabaseMachineRemoteDataSourceStub();

  @override
  Future<List<MachineModel>> fetchMachines() async => const [];

  @override
  Future<MachineModel?> fetchMachineById(String id) async => null;

  @override
  Future<void> syncMachine(MachineModel machine) async {
    // Queued for background sync when online
  }

  @override
  Future<void> syncProcessLog(ProcessLogModel log) async {
    // Queued for background sync when online
  }

  @override
  Future<List<MachineModel>> fetchModifiedAfter(DateTime cursor) async =>
      const [];
}
