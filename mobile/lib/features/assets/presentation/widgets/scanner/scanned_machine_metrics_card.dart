import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/department_type.dart';
import '../../../domain/enums/machine_status.dart';
import '../../../domain/models/machine_model.dart';

/// Row of mini spec metrics (Department, Status, Speed) inside ScannedMachineSheet.
class ScannedMachineMetricsCard extends StatelessWidget {
  final MachineModel machine;

  const ScannedMachineMetricsCard({
    super.key,
    required this.machine,
  });

  Widget _buildMetric({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDowntime = machine.status.isDowntime;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkNavy
            : AppColors.energyaLightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetric(
              context: context,
              label: context.tr('dept_label'),
              value: machine.department.localizedName(context.isArabic),
              icon: Icons.domain_rounded,
              color: context.isDarkMode
                  ? AppColors.electricBlue
                  : context.brandPrimary,
            ),
          ),
          Container(width: 1, height: 36, color: context.borderColor),
          Expanded(
            child: _buildMetric(
              context: context,
              label: context.tr('current_status_label'),
              value: machine.status.displayName,
              icon: Icons.circle,
              color: isDowntime
                  ? AppColors.downMaintenanceRed
                  : AppColors.runningEmerald,
            ),
          ),
          Container(width: 1, height: 36, color: context.borderColor),
          Expanded(
            child: _buildMetric(
              context: context,
              label: context.tr('instant_speed_label'),
              value: '${machine.currentSpeedMpm.toInt()} m/min',
              icon: Icons.speed_rounded,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
