import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';
import 'handshake/action_card_operator_test_run_section.dart';
import 'handshake/action_card_supervisor_assign_section.dart';
import 'handshake/action_card_supervisor_close_section.dart';
import 'handshake/action_card_tech_repair_section.dart';
import 'handshake/action_card_waiting_notice_section.dart';
import 'handshake/handshake_action_controller.dart';
import 'handshake/handshake_status_helper.dart';

/// Card orchestrating the 5-Step Maintenance Handshake interactive controls.
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
        final statusColor = getHandshakeStatusColor(status);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.2 : 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        color: context.isDarkMode
                            ? AppColors.cyberCyan
                            : context.brandPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      status.shortName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionContent(context, status, user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionContent(
    BuildContext context,
    WorkOrderStatus status,
    UserModel user,
  ) {
    final role = user.role;
    final controller = HandshakeActionController(
      context: context,
      workOrder: widget.workOrder,
    );

    // Step 2: Supervisor Assigns
    if (status == WorkOrderStatus.open &&
        role == UserRole.maintenanceSupervisor) {
      return ActionCardSupervisorAssignSection(
        workOrder: widget.workOrder,
        isProcessing: _isProcessing,
      );
    }

    // Step 3: Tech Starts or Completes Repair
    if ((status == WorkOrderStatus.assigned ||
            status == WorkOrderStatus.inProgress) &&
        role == UserRole.maintenanceTech) {
      return ActionCardTechRepairSection(
        workOrder: widget.workOrder,
        user: user,
        isProcessing: _isProcessing,
        onStartRepair: () => _handleAction(
          () => controller.startRepair(
            user,
            onStarted: widget.onRepairStarted,
          ),
        ),
        onCompleteRepair: () => _handleAction(
          () => controller.completeRepair(
            user,
            onCompleteRequested: widget.onCompleteRepairRequested,
          ),
        ),
      );
    }

    // Step 4: Operator Confirms Test Run
    if (status == WorkOrderStatus.completed && role == UserRole.operator) {
      return ActionCardOperatorTestRunSection(
        isProcessing: _isProcessing,
        onConfirmTestRun: () => _handleAction(
          () => controller.confirmTestRun(user),
        ),
      );
    }

    // Step 5: Supervisor Approves & Closes
    if (status == WorkOrderStatus.verified &&
        (role == UserRole.maintenanceSupervisor ||
            role == UserRole.productionSupervisor)) {
      return ActionCardSupervisorCloseSection(
        isProcessing: _isProcessing,
        onApproveAndClose: () => _handleAction(
          () => controller.approveAndClose(user),
        ),
      );
    }

    // Waiting Notice or Closed Complete
    return ActionCardWaitingNoticeSection(status: status);
  }
}
