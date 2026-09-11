import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/kpi_metric_card.dart';
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
        final hasDeptScope = userDept != null && !isPlantManager;

        int total = 0;
        int running = 0;
        int downtimes = 0;

        if (state is MachineLoaded) {
          final scopedMachines = hasDeptScope
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

        return SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              KpiMetricCard(
                title: context.tr('running'),
                value: '$running/$total',
                subtitle:
                    '${((running / (total > 0 ? total : 1)) * 100).toStringAsFixed(0)}% Active',
                icon: Icons.play_circle_fill_rounded,
                accentColor: AppColors.runningEmerald,
              ),
              const SizedBox(width: 10),
              KpiMetricCard(
                title: context.tr('active_downtime'),
                value: '$downtimes',
                subtitle: downtimes > 0
                    ? context.tr('requires_action')
                    : context.tr('all_clear'),
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.downMaintenanceRed,
              ),
              const SizedBox(width: 10),
              KpiMetricCard(
                title: hasDeptScope ? 'Dept OEE' : 'Plant OEE',
                value: '88.4%',
                subtitle: '+2.1% vs Target',
                icon: Icons.analytics_rounded,
                accentColor: context.brandPrimary,
              ),
            ],
          ),
        );
      },
    );
  }
}
