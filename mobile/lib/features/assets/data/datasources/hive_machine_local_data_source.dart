import 'package:hive/hive.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/process_log_model.dart';
import 'machine_local_data_source.dart';

/// Hive implementation of [MachineLocalDataSource].
///
/// Encapsulates direct Hive box operations for machines and process logs.
class HiveMachineLocalDataSource implements MachineLocalDataSource {
  Box<MachineModel> get _machinesBox =>
      Hive.box<MachineModel>(HiveBoxes.machinesBox);

  Box<ProcessLogModel> get _processLogsBox =>
      Hive.box<ProcessLogModel>(HiveBoxes.processLogsBox);

  @override
  Future<List<MachineModel>> getAllMachines() async {
    return _machinesBox.values.toList();
  }

  @override
  Future<MachineModel?> getMachineById(String id) async {
    final direct = _machinesBox.get(id);
    if (direct != null) return direct;
    try {
      return _machinesBox.values.firstWhere(
        (m) =>
            m.code.toLowerCase() == id.toLowerCase() ||
            m.id.toLowerCase() == id.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<MachineModel>> getMachinesByDepartment(
      DepartmentType department) async {
    return _machinesBox.values
        .where((m) => m.department == department)
        .toList();
  }

  @override
  Future<List<MachineModel>> getMachinesByStatus(MachineStatus status) async {
    return _machinesBox.values.where((m) => m.status == status).toList();
  }

  @override
  Future<void> cacheMachine(MachineModel machine) async {
    await _machinesBox.put(machine.id, machine);
  }

  @override
  Future<void> cacheMachines(List<MachineModel> machines) async {
    final map = {for (final m in machines) m.id: m};
    await _machinesBox.putAll(map);
  }

  @override
  Future<void> updateMachine(MachineModel machine) async {
    await _machinesBox.put(machine.id, machine);
  }

  @override
  Future<void> deleteMachine(String id) async {
    await _machinesBox.delete(id);
  }

  @override
  Future<void> saveProcessLog(ProcessLogModel log) async {
    await _processLogsBox.put(log.id, log);
  }

  @override
  Future<List<ProcessLogModel>> getProcessLogsForMachine(
      String machineId) async {
    return _processLogsBox.values
        .where((log) => log.machineId == machineId)
        .toList();
  }
}
