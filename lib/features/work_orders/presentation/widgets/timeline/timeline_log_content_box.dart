import 'package:flutter/material.dart';
import '../../../../../core/chronology/plant_shift.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/work_order_activity_log.dart';
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

          // Operational Details
          _buildDetailsTable(context, isDark),

          const SizedBox(height: 8),

          // Dual Timestamp & Shift Context
          _buildShiftBadge(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailsTable(BuildContext context, bool isDark) {
    final rawDetails = log.details ?? {};
    final operationalEntries = rawDetails.entries.where((entry) {
      final k = entry.key.toLowerCase();
      if (k.contains('time') ||
          k.contains('date') ||
          k == 'closedat' ||
          k == 'startedat' ||
          k == 'createdat') {
        return false;
      }
      final valStr = entry.value.toString();
      if (valStr.length >= 19 &&
          valStr.contains('T') &&
          DateTime.tryParse(valStr) != null) {
        return false;
      }
      return true;
    }).toList();

    if (operationalEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: operationalEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${TimelineStepHelper.formatDetailKey(context, entry.key)}: ',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShiftBadge(BuildContext context, bool isDark) {
    final chrono = log.effectiveChronology;
    final shift = chrono.activeShift;
    final shiftColor = shift.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : AppColors.slateBorder.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: shiftColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: shiftColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: shiftColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(shift.icon, size: 11, color: shiftColor),
                    const SizedBox(width: 4),
                    Text(
                      shift.localizedShortLabel(context.isArabic),
                      style: TextStyle(
                        color: shiftColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                shift.localizedName(context.isArabic),
                style: TextStyle(
                  color: shiftColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                context.trArgs('production_date_label', {
                  'date': chrono.productionDateFormatted,
                }),
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 10,
                ),
              ),
              if (chrono.isOfflineGenerated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.idleAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: AppColors.idleAmber,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: context.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.trArgs('time_label', {
                      'time': chrono.plantTimeOnlyFormatted,
                    }),
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 10,
                    color: context.textMutedColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'UTC: ${chrono.utcTimeOnlyFormatted}',
                    style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
