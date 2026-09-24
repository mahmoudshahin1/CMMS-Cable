import '../../domain/repositories/machine_repository.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/process_log_model.dart';
import '../datasources/machine_local_data_source.dart';
import '../datasources/hive_machine_local_data_source.dart';
import '../datasources/machine_remote_data_source.dart';

/// Repository orchestrator for Machines and Process Logs.
///
/// Coordinates between [MachineLocalDataSource] (Hive offline-first cache)
/// and optional [MachineRemoteDataSource] (Supabase remote backend).
class HiveMachineRepository implements MachineRepository {
  final MachineLocalDataSource _localDataSource;
  final MachineRemoteDataSource? _remoteDataSource;

  HiveMachineRepository({
    MachineLocalDataSource? localDataSource,
    MachineRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? HiveMachineLocalDataSource(),
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<MachineModel>> getAllMachines() async {
    return _localDataSource.getAllMachines();
  }

  @override
  Future<List<MachineModel>> refreshFromRemote() async {
    if (_remoteDataSource != null) {
      try {
        final remoteMachines = await _remoteDataSource.fetchMachines();
        if (remoteMachines.isNotEmpty) {
          await _localDataSource.cacheMachines(remoteMachines);
        }
      } catch (_) {
        // Fallback to local cache if network/remote fails
      }
    }
    return _localDataSource.getAllMachines();
  }

  @override
  Future<MachineModel?> getMachineById(String id) async {
    return _localDataSource.getMachineById(id);
  }

  @override
  Future<List<MachineModel>> getMachinesByDepartment(
      DepartmentType department) async {
    return _localDataSource.getMachinesByDepartment(department);
  }

  @override
  Future<List<MachineModel>> getMachinesByStatus(MachineStatus status) async {
    return _localDataSource.getMachinesByStatus(status);
  }

  @override
  Future<void> updateMachineStatus(
      String machineId, MachineStatus newStatus) async {
    final machine = await _localDataSource.getMachineById(machineId);
    if (machine != null) {
      final updated = machine.copyWith(status: newStatus);
      await _localDataSource.updateMachine(updated);
      _remoteDataSource?.syncMachine(updated);
    }
  }

  @override
  Future<void> saveProcessLog(ProcessLogModel log) async {
    await _localDataSource.saveProcessLog(log);

    // Update machine meter count and current speed in local cache
    final machine = await _localDataSource.getMachineById(log.machineId);
    if (machine != null) {
      final updatedMachine = machine.copyWith(
        currentSpeedMpm: log.speedMpm,
        totalMetersProduced: machine.totalMetersProduced + log.meterCount,
      );
      await _localDataSource.updateMachine(updatedMachine);
    }

    _remoteDataSource?.syncProcessLog(log);
  }

  @override
  Future<List<ProcessLogModel>> getProcessLogsForMachine(
      String machineId) async {
    return _localDataSource.getProcessLogsForMachine(machineId);
  }
}
