import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/work_order_model.dart';
import '../screens/work_order_detail_screen.dart';

enum FormSyncStatus { dirtyAmber, inFlightBlue, syncedGreen, errorRed }

/// Compact clickable chip representing an open work order form with sync state dot.
class OpenFormChip extends StatelessWidget {
  final WorkOrderModel workOrder;
  final FormSyncStatus syncStatus;

  const OpenFormChip({
    super.key,
    required this.workOrder,
    required this.syncStatus,
  });

  Color _getStatusDotColor() {
    switch (syncStatus) {
      case FormSyncStatus.dirtyAmber:
        return AppColors.idleAmber;
      case FormSyncStatus.inFlightBlue:
        return AppColors.electricBlue;
      case FormSyncStatus.errorRed:
        return AppColors.downMaintenanceRed;
      case FormSyncStatus.syncedGreen:
        return AppColors.runningEmerald;
    }
  }

  String _getTooltipText() {
    switch (syncStatus) {
      case FormSyncStatus.dirtyAmber:
        return 'Unsaved local outbox mutation (Dirty)';
      case FormSyncStatus.inFlightBlue:
        return 'Syncing to cloud in-flight';
      case FormSyncStatus.errorRed:
        return 'Sync error or version collision';
      case FormSyncStatus.syncedGreen:
        return 'Synced with cloud';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _getStatusDotColor();

    return Tooltip(
      message: _getTooltipText(),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkOrderDetailScreen(workOrder: workOrder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '#${workOrder.machineId}',
                style: TextStyle(
                  color: context.brandPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  workOrder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
