import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/enums/department_type.dart';
import 'downtime_report_sheet.dart';
import '../../../../core/localization/app_strings.dart';

class ScannedMachineSheet extends StatelessWidget {
  final MachineModel machine;

  const ScannedMachineSheet({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final isDowntime = machine.status.isDowntime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Machine Identified
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (context.isDarkMode
                            ? AppColors.cyberCyan
                            : context.brandPrimary)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_2_rounded,
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('machine_identified'),
                        style: const TextStyle(
                          color: AppColors.runningEmerald,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        machine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.darkNavy
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: context.isDarkMode
                            ? AppColors.cyberCyan
                            : context.brandPrimary),
                  ),
                  child: Text(
                    machine.code,
                    style: TextStyle(
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Machine specs mini cards
            Container(
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
            ),
            const SizedBox(height: 20),

            // Immediate Action 1: Create Repair Request
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close sheet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateRepairRequestScreen(initialMachine: machine),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.isDarkMode
                      ? AppColors.downMaintenanceRed
                      : AppColors.energyaAccentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_task_rounded, size: 20),
                label: Text(
                  context.tr('report_breakdown_immediate'),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Immediate Action 2: Report Downtime Sheet
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close scanned sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DowntimeReportSheet(machine: machine),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textPrimaryColor,
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.idleAmber, size: 20),
                label: Text(
                  context.tr('log_downtime_operational'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
}
