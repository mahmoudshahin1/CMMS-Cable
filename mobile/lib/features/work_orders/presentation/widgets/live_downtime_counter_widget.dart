import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';

enum LiveDowntimeStyle { badge, banner }

/// Periodic-tick widget showing elapsed downtime since work order [createdAt]
/// for any active work order (not completed, verified, or closed).
class LiveDowntimeCounterWidget extends StatefulWidget {
  final DateTime createdAt;
  final WorkOrderStatus status;
  final LiveDowntimeStyle style;

  const LiveDowntimeCounterWidget({
    super.key,
    required this.createdAt,
    required this.status,
    this.style = LiveDowntimeStyle.badge,
  });

  factory LiveDowntimeCounterWidget.fromWorkOrder(
    WorkOrderModel workOrder, {
    LiveDowntimeStyle style = LiveDowntimeStyle.badge,
  }) {
    return LiveDowntimeCounterWidget(
      createdAt: workOrder.createdAt,
      status: workOrder.status,
      style: style,
    );
  }

  @override
  State<LiveDowntimeCounterWidget> createState() =>
      _LiveDowntimeCounterWidgetState();
}

class _LiveDowntimeCounterWidgetState extends State<LiveDowntimeCounterWidget> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _calculateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_calculateElapsed);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveDowntimeCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.createdAt != widget.createdAt) {
      _calculateElapsed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateElapsed() {
    final now = DateTime.now();
    _elapsed = now.isAfter(widget.createdAt)
        ? now.difference(widget.createdAt)
        : Duration.zero;
  }

  bool get _isActive {
    return widget.status != WorkOrderStatus.completed &&
        widget.status != WorkOrderStatus.verified &&
        widget.status != WorkOrderStatus.verifiedClosed;
  }

  String _formatElapsed(bool isArabic) {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    if (isArabic) {
      if (hours > 0) {
        return 'متوقف منذ $hours س و $minutes د';
      }
      return 'متوقف منذ $minutes د و $seconds ث';
    } else {
      if (hours > 0) {
        return 'Down ${hours}h ${minutes}m so far';
      }
      return 'Down ${minutes}m ${seconds}s so far';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();

    final isArabic = context.isArabic;
    final label = _formatElapsed(isArabic);

    if (widget.style == LiveDowntimeStyle.banner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.downMaintenanceRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.downMaintenanceRed.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.downMaintenanceRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                color: AppColors.downMaintenanceRed,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? 'زمن التوقف الكلي للماكينة' : 'Total Machine Downtime Elapsed',
                    style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.downMaintenanceRed,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default: compact Badge/Chip
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.downMaintenanceRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.downMaintenanceRed.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 11,
            color: AppColors.downMaintenanceRed,
          ),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.downMaintenanceRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

