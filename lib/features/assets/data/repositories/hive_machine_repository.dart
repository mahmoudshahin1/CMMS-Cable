import 'package:hive/hive.dart';
import '../../domain/repositories/machine_repository.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/process_log_model.dart';
import '../../../../core/database/hive_boxes.dart';

class HiveMachineRepository implements MachineRepository {
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
  Future<void> updateMachineStatus(
      String machineId, MachineStatus newStatus) async {
    var machine = _machinesBox.get(machineId);
    if (machine == null) {
      try {
        machine = _machinesBox.values.firstWhere(
          (m) =>
              m.code.toLowerCase() == machineId.toLowerCase() ||
              m.id.toLowerCase() == machineId.toLowerCase(),
        );
      } catch (_) {
        machine = null;
      }
    }
    if (machine != null) {
      final updated = machine.copyWith(status: newStatus);
      await _machinesBox.put(machine.id, updated);
    }
  }

  @override
  Future<void> saveProcessLog(ProcessLogModel log) async {
    await _processLogsBox.put(log.id, log);

    // Also update machine meter count and speed
    final machine = _machinesBox.get(log.machineId);
    if (machine != null) {
      final updatedMachine = machine.copyWith(
        currentSpeedMpm: log.speedMpm,
        totalMetersProduced: machine.totalMetersProduced + log.meterCount,
      );
      await _machinesBox.put(machine.id, updatedMachine);
    }
  }

  @override
  Future<List<ProcessLogModel>> getProcessLogsForMachine(
      String machineId) async {
    return _processLogsBox.values
        .where((log) => log.machineId == machineId)
        .toList();
  }
}
