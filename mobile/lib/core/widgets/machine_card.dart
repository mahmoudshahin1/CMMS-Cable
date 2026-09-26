import 'package:flutter/material.dart';
import '../../features/assets/domain/models/machine_model.dart';
import '../../features/assets/domain/enums/machine_status.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class MachineCard extends StatefulWidget {
  final MachineModel machine;
  final VoidCallback onTap;
  final VoidCallback onReportDowntime;

  const MachineCard({
    super.key,
    required this.machine,
    required this.onTap,
    required this.onReportDowntime,
  });

  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDowntime = widget.machine.status.isDowntime;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                    : (context.isDarkMode
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.03)),
                blurRadius: context.isDarkMode ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? AppColors.darkNavy
                          : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Text(
                      widget.machine.code,
                      style: TextStyle(
                        color: context.isDarkMode
                            ? AppColors.cyberCyan
                            : AppColors.energyaPrimaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
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
              const SizedBox(height: 6),
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
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Divider(color: context.borderColor, height: 14),
              Row(
                children: [
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
                      value:
                          '${(widget.machine.totalMetersProduced / 1000).toStringAsFixed(1)}k m',
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
                        : (context.isDarkMode
                            ? AppColors.slateBorder
                            : const Color(0xFFE2E8F0)),
                    foregroundColor: isDowntime
                        ? Colors.white
                        : (context.isDarkMode
                            ? Colors.white
                            : AppColors.lightTextPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    isDowntime
                        ? Icons.build_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 14,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isDowntime ? 'VIEW DOWNTIME' : 'REPORT ISSUE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
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
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
