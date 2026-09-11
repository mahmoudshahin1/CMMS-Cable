import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/chronology/event_chronology.dart';
import '../../core/chronology/plant_shift.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';

class ShiftChronologyBadge extends StatefulWidget {
  /// If provided, displays this static chronology snapshot (e.g. For historical logs).
  /// If null, runs in live mode showing real-time plant shift and ticking plant clock.
  final EventChronology? chronology;

  /// If true, displays a compact single-line chip.
  final bool compact;

  /// Optional label prefix (e.g. "Record Time" or "Current Shift")
  final String? label;

  const ShiftChronologyBadge({
    super.key,
    this.chronology,
    this.compact = false,
    this.label,
  });

  @override
  State<ShiftChronologyBadge> createState() => _ShiftChronologyBadgeState();
}

class _ShiftChronologyBadgeState extends State<ShiftChronologyBadge> {
  Timer? _ticker;
  late EventChronology _current;

  @override
  void initState() {
    super.initState();
    _current = widget.chronology ?? EventChronology.now();
    if (widget.chronology == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _current = EventChronology.now();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShiftChronologyBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chronology != null) {
      _current = widget.chronology!;
      _ticker?.cancel();
      _ticker = null;
    } else if (_ticker == null) {
      _current = EventChronology.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _current = EventChronology.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = _current.activeShift;
    final shiftColor = shift.color;

    if (widget.compact) {
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
              _current.plantTimeFormatted,
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
          Wrap(
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
              if (widget.chronology == null)
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
          ),
          const SizedBox(height: 8),
          Wrap(
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
                    context.trArgs('plant_time_label', {'time': _current.plantTimeFormatted}),
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
                context.trArgs('prod_date_label', {'date': _current.productionDateFormatted}),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
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
                    'UTC: ${_current.recordedAtUtc.toIso8601String().substring(11, 19)}Z',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              if (_current.isOfflineGenerated)
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
          ),
        ],
      ),
    );
  }
}
