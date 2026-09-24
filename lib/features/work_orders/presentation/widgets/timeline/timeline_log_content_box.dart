import 'package:flutter/material.dart';
import '../../../../../core/auth/user_directory_helper.dart';
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
    final effectiveRole = (log.performedByRole == 'SYSTEM' || log.performedByRole.isEmpty)
        ? _inferRoleFromStep(log.stepName)
        : log.performedByRole;
    final roleColor = TimelineStepHelper.getRoleBadgeColor(effectiveRole);

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
                  effectiveRole,
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
          Builder(
            builder: (context) {
              final isOperatorDesk = log.performedByName == 'Operator Desk';
              final isSystemUser = log.performedByName == 'System User' ||
                  log.performedByName == 'System Automated';

              String resolvedName = isOperatorDesk
                  ? (UserDirectoryHelper.currentUser?.name ?? log.performedByName)
                  : (UserDirectoryHelper.resolveName(log.performedByName) ?? log.performedByName);

              if (isSystemUser) {
                final techInDetails = log.details?['technician'] as String?;
                final supInDetails = log.details?['supervisor'] as String?;
                final techIdInDetails = log.details?['technicianId'] as String?;
                final supIdInDetails = log.details?['supervisorId'] as String?;
                final actorInDetails = log.details?['actorId'] as String?;

                final fromDetails = techInDetails ??
                    supInDetails ??
                    UserDirectoryHelper.resolveName(techIdInDetails) ??
                    UserDirectoryHelper.resolveName(supIdInDetails) ??
                    UserDirectoryHelper.resolveName(actorInDetails);

                if (fromDetails != null && fromDetails.trim().isNotEmpty) {
                  resolvedName = fromDetails;
                } else if (UserDirectoryHelper.currentUser != null) {
                  resolvedName = UserDirectoryHelper.currentUser!.name;
                }
              }

              final resolvedEmail = (isOperatorDesk && log.performedByEmail.contains('system@'))
                  ? (UserDirectoryHelper.currentUser?.email ?? log.performedByEmail)
                  : (isSystemUser && UserDirectoryHelper.currentUser != null
                      ? (UserDirectoryHelper.currentUser?.email ?? log.performedByEmail)
                      : log.performedByEmail);

              return Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 13,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      resolvedName,
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
                      '($resolvedEmail)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),

          // Action Summary
          Text(
            UserDirectoryHelper.formatActionSummary(log.actionSummary),
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

  String _inferRoleFromStep(String stepName) {
    final upper = stepName.toUpperCase();
    if (upper.contains('REPAIR') || upper.contains('PART')) {
      return 'MAINTENANCE_TECH';
    }
    if (upper.contains('TEST') || upper.contains('REPORTED')) {
      return 'OPERATOR';
    }
    if (upper.contains('ASSIGN') || upper.contains('CLOSE') || upper.contains('STATUS')) {
      return 'MAINTENANCE_SUPERVISOR';
    }
    return 'SYSTEM';
  }
}
