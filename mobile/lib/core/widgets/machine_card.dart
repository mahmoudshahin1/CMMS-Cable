import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/assets/domain/models/machine_model.dart';
import '../../features/assets/domain/enums/machine_status.dart';
import '../../features/work_orders/domain/models/work_order_model.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';
import '../../features/work_orders/presentation/cubit/work_order_state.dart';
import '../../features/work_orders/presentation/widgets/live_downtime_counter_widget.dart';
import '../theme/app_colors.dart';
import 'pulse_dot.dart';
import 'ring_stat_card.dart';
import 'status_badge.dart';

/// Status-color mapping for the card's leading accent stripe -- mirrors
/// StatusBadge's own color choices (kept local/duplicated here rather than
/// exposing StatusBadge's private getter, so StatusBadge itself is untouched).
Color _stripeColorFor(MachineStatus status) {
  switch (status) {
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

class MachineCard extends StatefulWidget {
  final MachineModel machine;
  final WorkOrderModel? activeWorkOrder;
  final VoidCallback onTap;
  final VoidCallback onReportDowntime;

  const MachineCard({
    super.key,
    required this.machine,
    this.activeWorkOrder,
    required this.onTap,
    required this.onReportDowntime,
  });

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.96);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  WorkOrderModel? _resolveActiveWorkOrder(BuildContext context, bool isDowntime) {
    if (widget.activeWorkOrder != null) return widget.activeWorkOrder;
    if (!isDowntime) return null;
    try {
      final woState = context.watch<WorkOrderCubit>().state;
      if (woState is WorkOrderLoaded) {
        final mid = widget.machine.id.toLowerCase();
        final code = widget.machine.code.toLowerCase();
        for (final w in woState.activeWorkOrders) {
          final target = w.machineId.toLowerCase();
          if (target == mid || target == code) return w;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDowntime = widget.machine.status.isDowntime;
    final activeWo = _resolveActiveWorkOrder(context, isDowntime);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(context.isDarkMode ? 16 : 12),
            border: Border.all(
              color: isDowntime
                  ? AppColors.downMaintenanceRed.withValues(alpha: 0.8)
                  : context.borderColor,
              width: isDowntime ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDowntime
                    ? AppColors.downMaintenanceRed.withValues(alpha: 0.15)
                    : (context.isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.03)),
                blurRadius: context.isDarkMode ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leading status-colored stripe -- a nod to insulation
              // color-coding on real cable cores: each status gets its own
              // stripe color, same mapping StatusBadge already uses.
              Container(
                width: 4,
                color: _stripeColorFor(widget.machine.status),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? AppColors.darkNavy : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Text(
                      widget.machine.code,
                      style: TextStyle(
                        color: context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaPrimaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PulseDot(
                    color: _stripeColorFor(widget.machine.status),
                    size: 6,
                    animate: widget.machine.status == MachineStatus.running ||
                        isDowntime,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: StatusBadge(
                      status: widget.machine.status,
                      compact: true,
                    ),
                  ),
                ],
              ),
              if (activeWo != null) ...[
                const SizedBox(height: 4),
                LiveDowntimeCounterWidget.fromWorkOrder(activeWo),
              ],
              const SizedBox(height: 4),
              Text(
                widget.machine.name,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.machine.subCategory,
                style: TextStyle(color: context.textMutedColor, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Divider(color: context.borderColor, height: 12),
              Row(
                children: [
                  // Honest status gauge: a full ring reads as "running now",
                  // an empty track as "not running" -- there's no rated max
                  // speed on MachineModel to turn this into a true %, so we
                  // don't fabricate false precision.
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(30, 30),
                          painter: RingProgressPainter(
                            progress:
                                widget.machine.status == MachineStatus.running
                                    ? 0.82
                                    : 0.0,
                            trackColor: context.borderColor,
                            valueColor: _stripeColorFor(widget.machine.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetric(
                      context: context,
                      label: 'SPEED',
                      value: '${widget.machine.currentSpeedMpm.toInt()} m/pm',
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetric(
                      context: context,
                      label: 'PROD',
                      value: '${(widget.machine.totalMetersProduced / 1000).toStringAsFixed(1)}k m',
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: widget.onReportDowntime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDowntime
                        ? AppColors.downMaintenanceRed
                        : (context.isDarkMode ? AppColors.slateBorder : const Color(0xFFE2E8F0)),
                    foregroundColor: isDowntime
                        ? Colors.white
                        : (context.isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: Icon(
                    isDowntime ? Icons.build_circle_rounded : Icons.warning_amber_rounded,
                    size: 14,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isDowntime ? 'VIEW DOWNTIME' : 'REPORT ISSUE',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: context.textMutedColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.textMutedColor, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
