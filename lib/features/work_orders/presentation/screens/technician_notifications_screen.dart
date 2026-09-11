import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/priority.dart';
import 'work_order_detail_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/domain/enums/machine_status.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class TechnicianNotificationsScreen extends StatelessWidget {
  const TechnicianNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return Scaffold(
            body: Center(child: Text(context.tr('please_login'))),
          );
        }

        final currentUser = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('notifications_center_title')),
            actions: [
              const PersonaIndicatorChip(compact: true),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: context.tr('settings_title'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: BlocBuilder<WorkOrderCubit, WorkOrderState>(
            builder: (context, state) {
              if (state is WorkOrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<WorkOrderModel> allOrders = [];
              if (state is WorkOrderLoaded) {
                allOrders = state.allWorkOrders;
              }

              // Filter orders specifically assigned to this technician
              final assignedToMe = allOrders
                  .where((wo) => wo.assignedToTechnicianId == currentUser.id)
                  .toList();

              final newAssignments = assignedToMe
                  .where((wo) => wo.status == WorkOrderStatus.assigned)
                  .toList();

              final inProgress = assignedToMe
                  .where((wo) => wo.status == WorkOrderStatus.inProgress)
                  .toList();

              final recentlyCompleted = assignedToMe
                  .where((wo) =>
                      wo.status == WorkOrderStatus.completed ||
                      wo.status == WorkOrderStatus.verified ||
                      wo.status == WorkOrderStatus.verifiedClosed)
                  .toList();

              return RefreshIndicator(
                onRefresh: () => context.read<WorkOrderCubit>().loadWorkOrders(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Technician Greeting Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                .withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                .withValues(alpha: 0.15),
                            child: Icon(Icons.handyman_rounded,
                                color: context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary,
                                size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.name,
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.trArgs('maint_dept_speciality', {
                                    'spec': currentUser.speciality ??
                                        context.tr('maint_tech_default'),
                                  }),
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: newAssignments.isNotEmpty
                                  ? AppColors.downMaintenanceRed
                                      .withValues(alpha: 0.2)
                                  : AppColors.runningEmerald
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: newAssignments.isNotEmpty
                                    ? AppColors.downMaintenanceRed
                                    : AppColors.runningEmerald,
                              ),
                            ),
                            child: Text(
                              newAssignments.isNotEmpty
                                  ? context.trArgs('new_tasks_badge',
                                      {'count': '${newAssignments.length}'})
                                  : context.tr('ready_for_work'),
                              style: TextStyle(
                                color: newAssignments.isNotEmpty
                                    ? AppColors.downMaintenanceRed
                                    : AppColors.runningEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Urgent New Assignments
                    if (newAssignments.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.notification_important_rounded,
                              color: AppColors.downMaintenanceRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('new_tickets_waiting',
                                  {'count': '${newAssignments.length}'}),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...newAssignments.map((wo) => _buildAssignmentAlertCard(
                            context,
                            wo,
                            currentUser,
                          )),
                      const SizedBox(height: 20),
                    ],

                    // Section 2: In-Progress Repairs
                    if (inProgress.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: context.isDarkMode
                                  ? AppColors.electricBlue
                                  : context.brandPrimary,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('active_field_repairs',
                                  {'count': '${inProgress.length}'}),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...inProgress.map((wo) => _buildInProgressCard(context, wo)),
                      const SizedBox(height: 20),
                    ],

                    // Section 3: Completed History
                    if (recentlyCompleted.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.runningEmerald, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('repaired_orders_section',
                                  {'count': '${recentlyCompleted.length}'}),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...recentlyCompleted.take(3).map((wo) => _buildCompletedCard(context, wo)),
                    ],

                    // Empty state if completely no tickets
                    if (assignedToMe.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_turned_in_rounded,
                                size: 56, color: AppColors.runningEmerald.withValues(alpha: 0.7)),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('no_tickets_assigned_tech'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('no_tickets_assigned_sub'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignmentAlertCard(
      BuildContext context, WorkOrderModel wo, dynamic currentUser) {
    final isCritical = wo.priority == Priority.critical || wo.priority == Priority.high;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCritical ? AppColors.downMaintenanceRed : AppColors.idleAmber,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.downMaintenanceRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.trArgs('priority_label', {
                      'priority':
                          wo.priority.localizedName(context.isArabic).toUpperCase()
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.downMaintenanceRed,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.trArgs('machine_label', {'machine': wo.machineId}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wo.title,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wo.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkOrderDetailScreen(workOrder: wo),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: Text(context.tr('details_btn'),
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start Repair with Caller Authentication
                    context.read<WorkOrderCubit>().startRepair(
                          wo.id,
                          caller: currentUser,
                        );
                    context.read<MachineCubit>().updateMachineStatus(
                          wo.machineId,
                          MachineStatus.underRepair,
                        );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkOrderDetailScreen(workOrder: wo),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode
                        ? AppColors.electricBlue
                        : context.brandAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(context.tr('start_repair_btn'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressCard(BuildContext context, WorkOrderModel wo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (context.isDarkMode
                    ? AppColors.electricBlue
                    : context.brandPrimary)
                .withValues(alpha: 0.6)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: context.isDarkMode
              ? AppColors.electricBlue
              : context.brandPrimary,
          child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 22),
        ),
        title: Text(
          wo.title,
          style: TextStyle(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
        subtitle: Text(
          context.trArgs('repair_in_progress_banner', {'machine': wo.machineId}),
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.5),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WorkOrderDetailScreen(workOrder: wo),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.slateBorder
                  : context.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(context.tr('track_btn'),
                  style: const TextStyle(fontSize: 11.5)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, WorkOrderModel wo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.runningEmerald, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '${wo.machineId} • ${wo.status.localizedName(context.isArabic)}',
                  style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
