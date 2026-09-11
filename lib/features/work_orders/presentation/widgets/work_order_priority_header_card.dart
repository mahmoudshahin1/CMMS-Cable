import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/priority.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/models/work_order_model.dart';

/// Card displaying Work Order Priority, Type, Title, Machine ID, and Description.
class WorkOrderPriorityHeaderCard extends StatelessWidget {
  final WorkOrderModel workOrder;

  const WorkOrderPriorityHeaderCard({
    super.key,
    required this.workOrder,
  });

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.critical:
        return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(workOrder.priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDarkMode
              ? color.withValues(alpha: 0.6)
              : context.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRIORITY: ${workOrder.priority.displayName.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                workOrder.type.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workOrder.title,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Machine ID: ${workOrder.machineId}',
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workOrder.description,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
