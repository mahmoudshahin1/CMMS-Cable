import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/work_order_activity_log.dart';
import 'timeline_details_table.dart';
import 'timeline_shift_badge.dart';
import 'timeline_step_helper.dart';

/// Card rendering a single audit log entry with actor info, details table, and plant shift badges.
class TimelineLogContentBox extends StatelessWidget {
  final WorkOrderActivityLog log;

  const TimelineLogContentBox({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final stepColor = TimelineStepHelper.getStepColor(log.stepName);
    final roleColor = TimelineStepHelper.getRoleBadgeColor(log.performedByRole);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkNavy.withValues(alpha: 0.6)
            : AppColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stepColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Step Title + Role Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  TimelineStepHelper.getLocalizedStepTitle(
                    context,
                    log.stepName,
                  ),
                  style: TextStyle(
                    color: stepColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: roleColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  log.performedByRole,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Performed By Info
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 13,
                color: context.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  log.performedByName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '(${log.performedByEmail})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Summary
          Text(
            log.actionSummary,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),

          // Operational Details Table
          TimelineDetailsTable(details: log.details),

          const SizedBox(height: 8),

          // Dual Timestamp & Shift Context Badge
          TimelineShiftBadge(chronology: log.effectiveChronology),
        ],
      ),
    );
  }
}
