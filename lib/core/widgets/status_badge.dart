import 'package:flutter/material.dart';
import '../../features/assets/domain/enums/machine_status.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatefulWidget {
  final MachineStatus status;
  final bool animateGlow;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.animateGlow = true,
    this.compact = false,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animateGlow &&
        (widget.status.isDowntime || widget.status == MachineStatus.running)) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.animateGlow &&
          (widget.status.isDowntime ||
              widget.status == MachineStatus.running)) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case MachineStatus.running:
        return AppColors.runningEmerald;
      case MachineStatus.idle:
        return AppColors.idleAmber;
      case MachineStatus.downtimeProcess:
        return AppColors.downProcessOrange;
      case MachineStatus.downtimeMaintenance:
        return AppColors.downMaintenanceRed;
      case MachineStatus.preventiveMaintenance:
        return AppColors.underRepairPurple;
      case MachineStatus.offline:
        return AppColors.slateLight;
      case MachineStatus.underRepair:
        return AppColors.subduedViolet;
    }
  }

  IconData get _icon {
    switch (widget.status) {
      case MachineStatus.running:
        return Icons.play_circle_fill;
      case MachineStatus.idle:
        return Icons.pause_circle_filled;
      case MachineStatus.downtimeProcess:
        return Icons.warning_amber_rounded;
      case MachineStatus.downtimeMaintenance:
        return Icons.error_rounded;
      case MachineStatus.preventiveMaintenance:
        return Icons.build_circle_rounded;
      case MachineStatus.offline:
        return Icons.power_settings_new_rounded;
      case MachineStatus.underRepair:
        return Icons.handyman_rounded;
    }
  }

  String get _displayName {
    if (widget.compact) {
      switch (widget.status) {
        case MachineStatus.running:
          return 'RUNNING';
        case MachineStatus.downtimeProcess:
          return 'PROCESS';
        case MachineStatus.downtimeMaintenance:
          return 'MAINT.';
        case MachineStatus.preventiveMaintenance:
          return 'PREV. MAINT.';
        case MachineStatus.idle:
          return 'IDLE';
        case MachineStatus.offline:
          return 'OFFLINE';
        case MachineStatus.underRepair:
          return 'UNDER REPAIR';
      }
    }
    return widget.status.displayName.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowOpacity = (widget.status.isDowntime ||
                widget.status == MachineStatus.running)
            ? _glowAnimation.value
            : 0.3;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 6 : 10,
            vertical: widget.compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _color.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4 * glowOpacity),
                blurRadius: 10 * glowOpacity,
                spreadRadius: 2 * glowOpacity,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: widget.compact ? 12 : 14, color: _color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _color,
                    fontSize: widget.compact ? 9.5 : 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: widget.compact ? 0.3 : 0.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
