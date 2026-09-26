import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/work_order_status.dart';

/// Informational read-only notice card displayed when the current persona is waiting for another actor.
class ActionCardWaitingNoticeSection extends StatelessWidget {
  final WorkOrderStatus status;

  const ActionCardWaitingNoticeSection({
    super.key,
    required this.status,
  });

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

  @override
  Widget build(BuildContext context) {
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
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.runningEmerald,
              size: 20,
            ),
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
}
