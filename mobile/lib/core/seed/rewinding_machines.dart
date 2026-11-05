import '../../features/assets/domain/models/machine_model.dart';
import '../../features/assets/domain/enums/department_type.dart';
import '../../features/assets/domain/enums/machine_status.dart';

const List<MachineModel> rewindingMachines = [
  // 8. Rewinding Department (rewinding)
  MachineModel(
    id: 'RW01',
    code: 'RW01',
    name: 'Rewinding Line 01',
    department: DepartmentType.rewinding,
    status: MachineStatus.running,
    subCategory: 'Rewinder',
    currentSpeedMpm: 0.0, // TODO: Real operational stats from factory floor
    totalMetersProduced: 0.0, // TODO: Real operational stats from factory floor
  ),
  MachineModel(
    id: 'RW02',
    code: 'RW02',
    name: 'Rewinding Line 02',
    department: DepartmentType.rewinding,
    status: MachineStatus.running,
    subCategory: 'Rewinder',
    currentSpeedMpm: 0.0, // TODO: Real operational stats from factory floor
    totalMetersProduced: 0.0, // TODO: Real operational stats from factory floor
  ),
];

