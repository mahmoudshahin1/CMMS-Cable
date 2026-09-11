import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/work_order_status.dart';

/// Stepper widget displaying the 6 linear repair lifecycle states.
class WorkOrderStatusTimelineBar extends StatelessWidget {
  final WorkOrderStatus currentStatus;

  const WorkOrderStatusTimelineBar({
    super.key,
    required this.currentStatus,
  });

  static const List<WorkOrderStatus> _steps = [
    WorkOrderStatus.open,
    WorkOrderStatus.assigned,
    WorkOrderStatus.inProgress,
    WorkOrderStatus.completed,
    WorkOrderStatus.verified,
    WorkOrderStatus.verifiedClosed,
  ];

  String _stepLabel(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.open:
        return 'Report';
      case WorkOrderStatus.assigned:
        return 'Triage';
      case WorkOrderStatus.inProgress:
        return 'Repair';
      case WorkOrderStatus.completed:
        return 'Fixed';
      case WorkOrderStatus.verified:
        return 'Test Run';
      case WorkOrderStatus.verifiedClosed:
        return 'Closed';
      case WorkOrderStatus.pendingParts:
        return 'Parts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPAIR STATUS TIMELINE',
          style: TextStyle(
            color: context.isDarkMode
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _steps.map((status) {
            final isPassed = currentStatus.index >= status.index;
            final label = _stepLabel(status);

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isPassed
                          ? context.brandPrimary
                          : (context.isDarkMode
                              ? AppColors.slateBorder
                              : AppColors.energyaBorder),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPassed ? Icons.check : Icons.circle,
                      size: 13,
                      color: isPassed
                          ? Colors.white
                          : (context.isDarkMode
                              ? AppColors.textMuted
                              : AppColors.lightTextMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.isDarkMode
                            ? (isPassed ? Colors.white : AppColors.textMuted)
                            : (isPassed
                                ? AppColors.energyaTextPrimary
                                : AppColors.energyaTextMuted),
                        fontSize: 9.5,
                        fontWeight:
                            isPassed ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
