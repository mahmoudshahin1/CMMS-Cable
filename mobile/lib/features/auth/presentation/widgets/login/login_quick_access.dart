import 'package:flutter/material.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_colors.dart';
import 'package:orning_and_evening_remembrances/core/localization/app_strings.dart';

/// Interactive quick-access accounts panel for one-tap role selection.
class LoginQuickAccessPanel extends StatelessWidget {
  final bool isDark;
  final void Function(String email, String roleKey) onSelectAccount;

  const LoginQuickAccessPanel({
    super.key,
    required this.isDark,
    required this.onSelectAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.slateBorder.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0C4595).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: isDark
                    ? AppColors.cyberCyan.withValues(alpha: 0.8)
                    : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('login_quick_access_title'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Management row
          _buildRoleGroup(
            context,
            context.tr('login_group_management'),
            Icons.manage_accounts_rounded,
            AppColors.electricBlue,
            const [
              ('role_plant_manager', 'manager.prod@cable.com'),
              ('role_maintenance_supervisor', 'eng.maint@cable.com'),
              ('role_production_supervisor', 'prod.sup@cable.com'),
            ],
          ),
          const SizedBox(height: 10),
          // Technicians row
          _buildRoleGroup(
            context,
            context.tr('login_group_technicians'),
            Icons.build_rounded,
            AppColors.cyberCyan,
            const [
              ('role_electrical_technician', 'tech.elec@cable.com'),
              ('role_mechanical_technician', 'tech.mech@cable.com'),
            ],
          ),
          const SizedBox(height: 10),
          // Operators row
          _buildRoleGroup(
            context,
            context.tr('login_group_operators'),
            Icons.precision_manufacturing_rounded,
            const Color(0xFF10B981),
            const [
              ('line_drawing', 'op.drawing@cable.com'),
              ('line_stranding', 'operator@cable.com'),
              ('line_ccv', 'op.ccv@cable.com'),
              ('line_extrusion', 'op.extrusion@cable.com'),
              ('line_assembly', 'op.assembly@cable.com'),
              ('line_screening', 'op.screening@cable.com'),
              ('line_armouring', 'op.tape@cable.com'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleGroup(
    BuildContext context,
    String groupTitle,
    IconData icon,
    Color color,
    List<(String, String)> accounts,
  ) {
    final titleColor = isDark
        ? color.withValues(alpha: 0.9)
        : HSLColor.fromColor(color).withLightness(0.35).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: titleColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                groupTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Cairo',
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: accounts
              .map((a) => _buildQuickChip(context, a.$1, a.$2, color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickChip(
    BuildContext context,
    String labelKey,
    String email,
    Color accentColor,
  ) {
    final label = context.tr(labelKey);
    final chipTextColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : HSLColor.fromColor(accentColor).withLightness(0.3).toColor();

    final chipBgColor = isDark
        ? accentColor.withValues(alpha: 0.12)
        : accentColor.withValues(alpha: 0.08);

    final chipBorderColor = isDark
        ? accentColor.withValues(alpha: 0.35)
        : accentColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () => onSelectAccount(email, labelKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontFamily: 'Cairo',
            color: chipTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
