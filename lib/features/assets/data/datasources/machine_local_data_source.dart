import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';

/// Abstract contract for machine local persistence (Hive).
///
/// Implementations handle CRUD operations against the local cache.
abstract class MachineLocalDataSource {
  /// Returns all cached machines.
  Future<List<MachineModel>> getAllMachines();

  /// Returns a single machine by [id], or null if not found.
  Future<MachineModel?> getMachineById(String id);

  /// Returns machines filtered by [department].
  Future<List<MachineModel>> getMachinesByDepartment(DepartmentType department);

  /// Persists a [machine] to the local cache. Upserts by ID.
  Future<void> cacheMachine(MachineModel machine);

  /// Persists a batch of machines to the local cache.
  Future<void> cacheMachines(List<MachineModel> machines);

  /// Updates a single machine in the local cache.
  Future<void> updateMachine(MachineModel machine);

  /// Deletes a machine from the local cache by [id].
  Future<void> deleteMachine(String id);
}
