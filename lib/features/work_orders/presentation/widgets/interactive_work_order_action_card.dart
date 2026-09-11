import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../cubit/work_order_cubit.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/domain/enums/machine_status.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/models/user_model.dart';
import 'assign_technician_dialog.dart';
import '../../../../core/theme/app_colors.dart';

class InteractiveWorkOrderActionCard extends StatefulWidget {
  final WorkOrderModel workOrder;
  final VoidCallback? onRepairStarted;
  final VoidCallback? onCompleteRepairRequested;

  const InteractiveWorkOrderActionCard({
    super.key,
    required this.workOrder,
    this.onRepairStarted,
    this.onCompleteRepairRequested,
  });

  @override
  State<InteractiveWorkOrderActionCard> createState() =>
      _InteractiveWorkOrderActionCardState();
}

class _InteractiveWorkOrderActionCardState
    extends State<InteractiveWorkOrderActionCard> {
  bool _isProcessing = false;

  Future<void> _handleAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const SizedBox.shrink();
        }

        final user = authState.user;
        final status = widget.workOrder.status;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handshake Header
              Row(
                children: [
                  Icon(
                    Icons.handshake_rounded,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '5-STEP MAINTENANCE HANDSHAKE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.read<AuthCubit>().hasRole([
                          UserRole.maintenanceSupervisor,
                          UserRole.maintenanceTech,
                          UserRole.operator
                        ])
                            ? (context.isDarkMode
                                ? AppColors.cyberCyan
                                : context.brandPrimary)
                            : (context.isDarkMode
                                ? Colors.white70
                                : AppColors.energyaTextMuted),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusBadgeColor(status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _statusBadgeColor(status).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      status.shortName,
                      style: TextStyle(
                        color: _statusBadgeColor(status),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dynamic Action Logic
              _buildActionContent(context, status, user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionContent(
      BuildContext context, WorkOrderStatus status, UserModel user) {
    final role = user.role;
    // Step 1 -> 2: Pending ticket, Supervisor assigns tech
    if ((status == WorkOrderStatus.open) &&
        role == UserRole.maintenanceSupervisor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Triage breakdown and dispatch an Electrical or Mechanical technician.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => AssignTechnicianDialog.show(context, widget.workOrder),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.subduedViolet
                  : context.brandPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text(
              'Step 2: Assign Technician',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Step 2 -> 3: Assigned ticket, Tech starts repair
    if (status == WorkOrderStatus.assigned &&
        role == UserRole.maintenanceTech) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Accept ticket and commence on-site diagnostic & repair.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _handleAction(() async {
                      // Start Repair with caller authentication
                      await context.read<WorkOrderCubit>().startRepair(
                            widget.workOrder.id,
                            caller: user,
                          );
                      // Update Machine to underRepair
                      if (context.mounted) {
                        await context
                            .read<MachineCubit>()
                            .updateMachineStatus(
                              widget.workOrder.machineId,
                              MachineStatus.underRepair,
                            );
                      }
                      widget.onRepairStarted?.call();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Repair started! Machine set to UNDER REPAIR and MTTR timer activated.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.isDarkMode
                                ? AppColors.slateCard
                                : AppColors.energyaDeepNavy,
                          ),
                        );
                      }
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.electricBlue
                  : context.brandAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              _isProcessing
                  ? 'Starting Repair...'
                  : 'Step 3: Start Repair (Begin MTTR)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Step 3 -> 4: In Progress, Tech completes repair
    if (status == WorkOrderStatus.inProgress &&
        role == UserRole.maintenanceTech) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Record replaced spare parts and root cause, then complete field repair.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _handleAction(() async {
                      if (widget.onCompleteRepairRequested != null) {
                        widget.onCompleteRepairRequested!();
                      } else {
                        await context
                            .read<WorkOrderCubit>()
                            .completeWorkOrder(
                              widget.workOrder.id,
                              rootCause: 'Maintenance fix completed',
                              actionsTaken: 'Field repair completed',
                              caller: user,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Repair completed! Waiting for Operator field test run.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: context.isDarkMode
                                  ? AppColors.slateCard
                                  : AppColors.energyaDeepNavy,
                            ),
                          );
                        }
                      }
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.runningEmerald,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _isProcessing ? 'Completing...' : 'Complete Field Repair',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Step 4 -> 5: Completed repair, Operator confirms test run
    if (status == WorkOrderStatus.completed && role == UserRole.operator) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Perform field line test run with raw material and verify stable operation.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _handleAction(() async {
                      final messenger = ScaffoldMessenger.of(context);
                      final machineCubit = context.read<MachineCubit>();
                      final workOrderCubit = context.read<WorkOrderCubit>();
                      final snackBg = context.isDarkMode
                          ? AppColors.slateCard
                          : AppColors.energyaDeepNavy;
                      // Confirm test run with caller authentication
                      await workOrderCubit.confirmTestRun(
                            widget.workOrder.id,
                            caller: user,
                          );
                      // Return machine to RUNNING!
                      await machineCubit.updateMachineStatus(
                        widget.workOrder.machineId,
                        MachineStatus.running,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Test run confirmed! Machine is now RUNNING. Ticket forwarded for Supervisor sign-off.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: snackBg,
                        ),
                      );
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.runningEmerald,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.fact_check_rounded, size: 18),
            label: Text(
              _isProcessing
                  ? 'Verifying...'
                  : 'Step 4: Confirm Test Run & Line Ready',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Step 5 -> Closed: Verified ticket, Supervisor approves & closes
    if (status == WorkOrderStatus.verified &&
        (role == UserRole.maintenanceSupervisor ||
            role == UserRole.productionSupervisor)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Review MTTR duration, spare parts consumed, and officially close ticket.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _handleAction(() async {
                      // Approve and close with caller authentication
                      await context.read<WorkOrderCubit>().approveAndClose(
                            widget.workOrder.id,
                            caller: user,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Work order approved and closed successfully. Archive updated.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.isDarkMode
                                ? AppColors.slateCard
                                : AppColors.energyaDeepNavy,
                          ),
                        );
                      }
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
              foregroundColor:
                  context.isDarkMode ? Colors.black : Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.task_alt_rounded, size: 18),
            label: Text(
              _isProcessing
                  ? 'Closing...'
                  : 'Step 5: Approve & Close Work Order',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // Ticket is closed
    if (status == WorkOrderStatus.verifiedClosed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.runningEmerald.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.runningEmerald.withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.runningEmerald, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ticket Lifecycle Complete: Handshake verified, line operational, order closed.',
                style: TextStyle(
                  color: AppColors.runningEmerald,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Read-only / Inactive state for unauthorized personas
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.darkNavy
            : AppColors.energyaLightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_clock_rounded,
            color: context.isDarkMode
                ? AppColors.cyberCyan
                : context.brandPrimary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getWaitingNotice(status),
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWaitingNotice(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return 'Step 1 complete. Awaiting Maintenance Supervisor to dispatch a technician.';
      case WorkOrderStatus.assigned:
        return 'Step 2 complete. Awaiting assigned Maintenance Technician to accept & start repair.';
      case WorkOrderStatus.inProgress:
        return 'Step 3 in progress. Field repair and diagnostic underway by Technician.';
      case WorkOrderStatus.pendingParts:
        return 'Waiting on spare parts delivery before repair can proceed.';
      case WorkOrderStatus.completed:
        return 'Step 3 complete. Awaiting Line Operator to perform test run and confirm machine readiness.';
      case WorkOrderStatus.verified:
        return 'Step 4 complete. Awaiting Supervisor to review downtime and close order.';
      case WorkOrderStatus.verifiedClosed:
        return 'Work order is closed.';
    }
  }

  Color _statusBadgeColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return AppColors.downMaintenanceRed;
      case WorkOrderStatus.assigned:
        return AppColors.idleAmber;
      case WorkOrderStatus.inProgress:
        return AppColors.electricBlue;
      case WorkOrderStatus.pendingParts:
        return AppColors.idleAmber;
      case WorkOrderStatus.completed:
        return AppColors.cyberCyan;
      case WorkOrderStatus.verified:
        return AppColors.subduedViolet;
      case WorkOrderStatus.verifiedClosed:
        return AppColors.runningEmerald;
    }
  }
}
