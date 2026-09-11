import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/machine_card.dart';
import '../../../../auth/domain/enums/user_role.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../../domain/enums/department_type.dart';
import '../../../domain/models/machine_model.dart';
import '../../cubit/machine_cubit.dart';
import '../../cubit/machine_state.dart';

/// Responsive sliver grid rendering plant machines with state handling.
class PlantMachineSliverGrid extends StatelessWidget {
  final void Function(MachineModel machine) onReportDowntime;

  const PlantMachineSliverGrid({
    super.key,
    required this.onReportDowntime,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MachineCubit, MachineState>(
      builder: (context, state) {
        final currentUser = context.watch<AuthCubit>().currentUser;
        final userDept = currentUser?.department;
        final isPlantManager = currentUser?.role == UserRole.plantManager;
        final hasDeptScope = userDept != null && !isPlantManager;

        if (state is MachineLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is MachineError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Error: ${state.message}')),
          );
        }
        if (state is MachineLoaded) {
          final machines = hasDeptScope
              ? state.allMachines
                  .where((m) => m.department == userDept)
                  .toList()
              : state.filteredMachines;

          if (machines.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    hasDeptScope
                        ? context.trArgs('no_dept_machines', {
                            'dept': userDept.localizedName(context.isArabic),
                          })
                        : context.tr('no_machines_found'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            );
          }

          return SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = ResponsiveHelper.gridColumnCount(
                constraints.crossAxisExtent,
              );
              final aspectRatio = ResponsiveHelper.machineCardAspectRatio(
                constraints.crossAxisExtent,
              );
              final padding = ResponsiveHelper.horizontalPadding(
                constraints.crossAxisExtent,
              );

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final machine = machines[index];
                      return MachineCard(
                        machine: machine,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateRepairRequestScreen(
                                initialMachine: machine,
                              ),
                            ),
                          );
                        },
                        onReportDowntime: () => onReportDowntime(machine),
                      );
                    },
                    childCount: machines.length,
                  ),
                ),
              );
            },
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
