import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/ring_stat_card.dart';
import '../../../../auth/domain/enums/user_role.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/enums/machine_status.dart';
import '../../cubit/machine_cubit.dart';
import '../../cubit/machine_state.dart';

/// Horizontal KPI ribbon displaying Active Machines count, Downtime count, and OEE %.
class PlantFactoryKpiBar extends StatelessWidget {
  const PlantFactoryKpiBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MachineCubit, MachineState>(
      builder: (context, state) {
        final currentUser = context.watch<AuthCubit>().currentUser;
        final userDept = currentUser?.department;
        final isPlantManager =
            currentUser?.role == UserRole.plantManager;
        final isOperator =
            currentUser?.role == UserRole.operator;
        final hasDeptScope = isOperator || (userDept != null && !isPlantManager);

        int total = 0;
        int running = 0;
        int downtimes = 0;

        if (state is MachineLoaded) {
          final scopedMachines = (hasDeptScope && userDept != null)
              ? state.allMachines
                  .where((m) => m.department == userDept)
                  .toList()
              : state.allMachines;

          total = scopedMachines.length;
          running = scopedMachines
              .where((m) => m.status == MachineStatus.running)
              .length;
          downtimes = scopedMachines
              .where((m) => m.status.isDowntime)
              .length;
        }

        final runningFraction = running / (total > 0 ? total : 1);
        final downtimeFraction = downtimes / (total > 0 ? total : 1);

        return SizedBox(
          height: 116,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              RingStatCard(
                label: context.tr('running'),
                centerValue: '$running/$total',
                footnote: '${(runningFraction * 100).toStringAsFixed(0)}% Active',
                progress: runningFraction,
                color: AppColors.runningEmerald,
              ),
              const SizedBox(width: 10),
              RingStatCard(
                label: context.tr('active_downtime'),
                centerValue: '$downtimes',
                footnote: downtimes > 0
                    ? context.tr('requires_action')
                    : context.tr('all_clear'),
                progress: downtimes > 0 ? downtimeFraction : 0.0,
                color: AppColors.downMaintenanceRed,
              ),
              const SizedBox(width: 10),
              RingStatCard(
                label: hasDeptScope ? 'Dept OEE' : 'Plant OEE',
                centerValue: '88.4%',
                footnote: '+2.1% vs Target',
                progress: 0.884,
                color: context.brandPrimary,
              ),
            ],
          ),
        );
      },
    );
  }
}
