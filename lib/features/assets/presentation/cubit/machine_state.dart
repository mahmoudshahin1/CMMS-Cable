import 'package:equatable/equatable.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';

abstract class MachineState extends Equatable {
  const MachineState();

  @override
  List<Object?> get props => [];
}

class MachineInitial extends MachineState {}

class MachineLoading extends MachineState {}

class MachineLoaded extends MachineState {
  final List<MachineModel> allMachines;
  final List<MachineModel> filteredMachines;
  final DepartmentType? selectedDepartment;
  final MachineStatus? selectedStatusFilter;

  const MachineLoaded({
    required this.allMachines,
    required this.filteredMachines,
    this.selectedDepartment,
    this.selectedStatusFilter,
  });

  MachineLoaded copyWith({
    List<MachineModel>? allMachines,
    List<MachineModel>? filteredMachines,
    DepartmentType? selectedDepartment,
    MachineStatus? selectedStatusFilter,
  }) {
    return MachineLoaded(
      allMachines: allMachines ?? this.allMachines,
      filteredMachines: filteredMachines ?? this.filteredMachines,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
    );
  }

  @override
  List<Object?> get props => [
        allMachines,
        filteredMachines,
        selectedDepartment,
        selectedStatusFilter,
      ];
}

class MachineError extends MachineState {
  final String message;

  const MachineError(this.message);

  @override
  List<Object?> get props => [message];
}
