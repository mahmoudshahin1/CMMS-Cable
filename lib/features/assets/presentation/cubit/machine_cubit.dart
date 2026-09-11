import 'package:flutter_bloc/flutter_bloc.dart';
import 'machine_state.dart';
import '../../domain/repositories/machine_repository.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/process_log_model.dart';

class MachineCubit extends Cubit<MachineState> {
  final MachineRepository repository;

  MachineCubit(this.repository) : super(MachineInitial());

  Future<void> loadMachines() async {
    emit(MachineLoading());
    try {
      final machines = await repository.getAllMachines();
      emit(MachineLoaded(
        allMachines: machines,
        filteredMachines: machines,
      ));
    } catch (e) {
      emit(MachineError('Failed to load machines: ${e.toString()}'));
    }
  }

  void filterByDepartment(DepartmentType? department) {
    if (state is MachineLoaded) {
      final current = state as MachineLoaded;
      emit(current.copyWith(
        filteredMachines: _applyFilters(
          current.allMachines,
          department,
          current.selectedStatusFilter,
        ),
        selectedDepartment: department,
      ));
    }
  }

  void filterByStatus(MachineStatus? status) {
    if (state is MachineLoaded) {
      final current = state as MachineLoaded;
      emit(current.copyWith(
        filteredMachines: _applyFilters(
          current.allMachines,
          current.selectedDepartment,
          status,
        ),
        selectedStatusFilter: status,
      ));
    }
  }

  List<MachineModel> _applyFilters(
    List<MachineModel> all,
    DepartmentType? dept,
    MachineStatus? status,
  ) {
    return all.where((m) {
      final matchesDept = dept == null || m.department == dept;
      final matchesStatus = status == null || m.status == status;
      return matchesDept && matchesStatus;
    }).toList();
  }

  Future<void> updateMachineStatus(String machineId, MachineStatus newStatus) async {
    try {
      await repository.updateMachineStatus(machineId, newStatus);
      await loadMachines();
    } catch (e) {
      emit(MachineError('Failed to update machine status: ${e.toString()}'));
    }
  }

  Future<void> logRunningParameters(ProcessLogModel log) async {
    try {
      await repository.saveProcessLog(log);
      await loadMachines();
    } catch (e) {
      emit(MachineError('Failed to log process parameters: ${e.toString()}'));
    }
  }
}
