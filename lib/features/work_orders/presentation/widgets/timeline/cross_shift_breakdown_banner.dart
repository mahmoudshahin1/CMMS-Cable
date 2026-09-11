import 'package:flutter/material.dart';
import '../../../../../core/chronology/event_chronology.dart';
import '../../../../../core/chronology/plant_shift.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/work_order_activity_log.dart';
import '../../../domain/models/work_order_model.dart';

/// Warning and duration breakdown banner for work orders spanning across plant shifts.
class CrossShiftBreakdownBanner extends StatelessWidget {
  final WorkOrderModel? workOrder;
  final List<WorkOrderActivityLog> activityLogs;

  const CrossShiftBreakdownBanner({
    super.key,
    required this.workOrder,
    required this.activityLogs,
  });

  @override
  Widget build(BuildContext context) {
    final originChrono = workOrder?.effectiveChronology ??
        (activityLogs.isNotEmpty
            ? activityLogs.first.effectiveChronology
            : null);
    if (originChrono == null) return const SizedBox.shrink();

    final currentOrEndChrono = activityLogs.isNotEmpty
        ? activityLogs.last.effectiveChronology
        : EventChronology.now();

    final isCross = workOrder?.isCrossShift ??
        currentOrEndChrono.isCrossShiftFrom(originChrono);

    if (!isCross) return const SizedBox.shrink();

    final originShift = originChrono.activeShift;
    final currentShift = currentOrEndChrono.activeShift;

    final startUtc = originChrono.recordedAtUtc;
    final endUtc = workOrder?.completedAt?.toUtc() ??
        currentOrEndChrono.recordedAtUtc;
    final duration = endUtc.isAfter(startUtc)
        ? endUtc.difference(startUtc)
        : Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationFormatted = '${hours}h ${minutes}m';

    final startTimeFormatted = originChrono.plantTimeFormatted.length >= 16
        ? originChrono.plantTimeFormatted.substring(11, 16)
        : originChrono.plantTimeFormatted;

    final shiftMinutes =
        EventChronology.computeDowntimeMinutesPerShift(startUtc, endUtc);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.underRepairPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.underRepairPurple.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.underRepairPurple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.underRepairPurple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('cross_shift_title'),
                  style: const TextStyle(
                    color: AppColors.underRepairPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.trArgs('cross_shift_start', {
              'time': startTimeFormatted,
              'shift': originShift.localizedName(context.isArabic),
            }),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.trArgs('cross_shift_extended', {
              'shift': currentShift.localizedName(context.isArabic),
              'time': startTimeFormatted,
              'duration': durationFormatted,
            }),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('cross_shift_oee_dist'),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: shiftMinutes.entries
                .where((e) => e.value > 0)
                .map((entry) {
              final s = entry.key;
              final mins = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: s.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  context.trArgs('shift_minutes', {
                    'label': s.localizedShortLabel(context.isArabic),
                    'mins': mins.toString(),
                  }),
                  style: TextStyle(
                    color: s.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
