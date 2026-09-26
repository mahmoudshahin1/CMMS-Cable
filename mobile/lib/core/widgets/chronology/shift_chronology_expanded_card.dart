import 'package:flutter/material.dart';
import '../../chronology/event_chronology.dart';
import '../../chronology/plant_shift.dart';
import '../../localization/app_strings.dart';
import '../../theme/app_colors.dart';

class ShiftChronologyExpandedCard extends StatelessWidget {
  final EventChronology chronology;
  final bool isLive;

  const ShiftChronologyExpandedCard({
    super.key,
    required this.chronology,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final shift = chronology.activeShift;
    final shiftColor = shift.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shiftColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: shiftColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShiftHeader(context),
          const SizedBox(height: 8),
          _buildTimeRow(context),
          const SizedBox(height: 4),
          _buildUtcAndOfflineRow(),
        ],
      ),
    );
  }

  Widget _buildShiftHeader(BuildContext context) {
    final shift = chronology.activeShift;
    final shiftColor = shift.color;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: shiftColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: shiftColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(shift.icon, size: 14, color: shiftColor),
                  const SizedBox(width: 6),
                  Text(
                    '${shift.code} • ${shift.localizedName(context.isArabic)}',
                    style: TextStyle(
                      color: shiftColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              shift.timeRange,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        if (isLive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.runningEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.runningEmerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.runningEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeRow(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded,
                size: 15, color: AppColors.cyberCyan),
            const SizedBox(width: 6),
            Text(
              context.trArgs('plant_time_label',
                  {'time': chronology.plantTimeFormatted}),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Text(
          context.trArgs('prod_date_label',
              {'date': chronology.productionDateFormatted}),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUtcAndOfflineRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'UTC: ${chronology.recordedAtUtc.toIso8601String().substring(11, 19)}Z',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        if (chronology.isOfflineGenerated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.idleAmber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'OFFLINE SYNCED',
              style: TextStyle(
                color: AppColors.idleAmber,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
