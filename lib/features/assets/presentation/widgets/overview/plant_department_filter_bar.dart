import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/department_chip_bar.dart';
import '../../../../auth/domain/enums/user_role.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/machine_cubit.dart';
import '../../cubit/machine_state.dart';

/// Department horizontal filter chips locked to user department when scoped.
class PlantDepartmentFilterBar extends StatelessWidget {
  const PlantDepartmentFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MachineCubit, MachineState>(
      builder: (context, state) {
        final currentUser = context.watch<AuthCubit>().currentUser;
        final userDept = currentUser?.department;
        final isPlantManager = currentUser?.role == UserRole.plantManager;
        final isOperator = currentUser?.role == UserRole.operator;
        final hasDeptScope = isOperator || (userDept != null && !isPlantManager);

        final selectedDept = (hasDeptScope && userDept != null)
            ? userDept
            : ((state is MachineLoaded) ? state.selectedDepartment : null);

        return DepartmentChipBar(
          selectedDepartment: selectedDept,
          availableDepartments: (hasDeptScope && userDept != null) ? [userDept] : null,
          showAllOption: !hasDeptScope,
          onDepartmentSelected: (dept) {
            if (!hasDeptScope) {
              context.read<MachineCubit>().filterByDepartment(dept);
            }
          },
        );
      },
    );
  }
}
