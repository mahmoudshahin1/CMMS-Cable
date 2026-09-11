import 'package:flutter/material.dart';
import '../../chronology/event_chronology.dart';
import '../../chronology/plant_shift.dart';
import '../../localization/app_strings.dart';
import '../../theme/app_colors.dart';

class ShiftChronologyCompactChip extends StatelessWidget {
  final EventChronology chronology;

  const ShiftChronologyCompactChip({
    super.key,
    required this.chronology,
  });

  @override
  Widget build(BuildContext context) {
    final shift = chronology.activeShift;
    final shiftColor = shift.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: shiftColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: shiftColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shift.icon, size: 13, color: shiftColor),
          const SizedBox(width: 5),
          Text(
            '${shift.code} (${shift.localizedName(context.isArabic)})',
            style: TextStyle(
              color: shiftColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: shiftColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            chronology.plantTimeFormatted,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
