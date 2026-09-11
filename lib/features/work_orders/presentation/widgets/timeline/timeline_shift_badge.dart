import 'package:flutter/material.dart';
import '../../../../../core/chronology/event_chronology.dart';
import '../../../../../core/chronology/plant_shift.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Shift context badge and dual timestamps (plant time & UTC) for an audit log entry.
class TimelineShiftBadge extends StatelessWidget {
  final EventChronology chronology;

  const TimelineShiftBadge({
    super.key,
    required this.chronology,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final shift = chronology.activeShift;
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
                  'date': chronology.productionDateFormatted,
                }),
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 10,
                ),
              ),
              if (chronology.isOfflineGenerated)
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
                      'time': chronology.plantTimeOnlyFormatted,
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
                    'UTC: ${chronology.utcTimeOnlyFormatted}',
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
