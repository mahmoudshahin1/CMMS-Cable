import '../models/machine_model.dart';
import '../enums/department_type.dart';
import '../enums/machine_status.dart';
import '../models/process_log_model.dart';

abstract class MachineRepository {
  Future<List<MachineModel>> getAllMachines();
  Future<MachineModel?> getMachineById(String id);
  Future<List<MachineModel>> getMachinesByDepartment(DepartmentType department);
  Future<List<MachineModel>> getMachinesByStatus(MachineStatus status);
  Future<void> updateMachineStatus(String machineId, MachineStatus newStatus);
  Future<void> saveProcessLog(ProcessLogModel log);
  Future<List<ProcessLogModel>> getProcessLogsForMachine(String machineId);
}
