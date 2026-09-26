import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../domain/models/machine_model.dart';
import 'downtime_report_sheet.dart';
import 'scanner/scanned_machine_metrics_card.dart';

/// Modal sheet opened upon scanning an asset QR code to show live state and quick actions.
class ScannedMachineSheet extends StatelessWidget {
  final MachineModel machine;

  const ScannedMachineSheet({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
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
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 24,
                  ),
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
                          : context.brandPrimary,
                    ),
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
            ScannedMachineMetricsCard(machine: machine),
            const SizedBox(height: 20),
            RoleGuard(
              allowedRoles: const [
                UserRole.operator,
                UserRole.maintenanceSupervisor,
              ],
              child: Builder(
                builder: (context) {
                  final currentUser = context.watch<AuthCubit>().currentUser;
                  final isOperator = currentUser?.role == UserRole.operator;
                  final isOtherDept = isOperator &&
                      currentUser?.department != null &&
                      machine.department != currentUser!.department;

                  if (isOtherDept) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.downMaintenanceRed
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.downMaintenanceRed
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: AppColors.downMaintenanceRed,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('operator_machine_permission_denied'),
                              style: const TextStyle(
                                color: AppColors.downMaintenanceRed,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateRepairRequestScreen(
                                  initialMachine: machine,
                                ),
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
                            context.tr('report_breakdown_btn'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  DowntimeReportSheet(machine: machine),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimaryColor,
                            side: BorderSide(color: context.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.idleAmber,
                            size: 20,
                          ),
                          label: Text(
                            context.tr('log_downtime_operational'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
