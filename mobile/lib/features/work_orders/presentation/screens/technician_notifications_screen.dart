import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../widgets/notifications/assignment_alert_card.dart';
import '../widgets/notifications/completed_repair_card.dart';
import '../widgets/notifications/in_progress_repair_card.dart';
import '../widgets/notifications/technician_empty_state.dart';
import '../widgets/notifications/technician_greeting_card.dart';

/// Screen displaying active maintenance dispatches and notifications for technicians.
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
                onRefresh: () =>
                    context.read<WorkOrderCubit>().loadWorkOrders(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TechnicianGreetingCard(
                      currentUser: currentUser,
                      newAssignmentsCount: newAssignments.length,
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Urgent New Assignments
                    if (newAssignments.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.notification_important_rounded,
                            color: AppColors.downMaintenanceRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('new_tickets_waiting', {
                                'count': '${newAssignments.length}',
                              }),
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
                      ...newAssignments.map(
                        (wo) => AssignmentAlertCard(
                          workOrder: wo,
                          currentUser: currentUser,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section 2: In-Progress Repairs
                    if (inProgress.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: context.isDarkMode
                                ? AppColors.electricBlue
                                : context.brandPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('active_field_repairs', {
                                'count': '${inProgress.length}',
                              }),
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
                      ...inProgress.map(
                        (wo) => InProgressRepairCard(workOrder: wo),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section 3: Completed History
                    if (recentlyCompleted.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.runningEmerald,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('repaired_orders_section', {
                                'count': '${recentlyCompleted.length}',
                              }),
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
                      ...recentlyCompleted
                          .take(3)
                          .map((wo) => CompletedRepairCard(workOrder: wo)),
                    ],

                    // Empty state
                    if (assignedToMe.isEmpty) const TechnicianEmptyState(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
