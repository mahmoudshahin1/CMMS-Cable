import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/models/user_model.dart';

/// Scope & RBAC indicator banner displayed at the top of the Work Orders list.
class WorkOrderScopeBanner extends StatelessWidget {
  final UserModel? currentUser;
  final int scopedCount;
  final int allCount;
  final int pendingAssignmentsCount;

  const WorkOrderScopeBanner({
    super.key,
    required this.currentUser,
    required this.scopedCount,
    required this.allCount,
    required this.pendingAssignmentsCount,
  });

  @override
  Widget build(BuildContext context) {
    final isTech = currentUser?.role == UserRole.maintenanceTech;
    final isPlantManager = currentUser?.role == UserRole.plantManager;
    final userDept = currentUser?.department;
    final hasDeptScope = userDept != null && !isPlantManager;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDeptScope)
          _buildScopeCard(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: context.isDarkMode
                ? AppColors.cyberCyan
                : AppColors.energyaPrimaryBlue,
            title: context.trArgs('dept_scope_label', {
              'dept': userDept.displayName,
            }),
            subtitle: context.tr('dept_scope_sub'),
            badgeText: context.trArgs(
              'ticket_count',
              {'count': scopedCount.toString()},
            ),
            accentColor: AppColors.cyberCyan,
          ),
        if (isPlantManager)
          _buildPlantManagerCard(context),
        if (isTech)
          _buildTechnicianCard(context),
        if (isTech && pendingAssignmentsCount > 0)
          _buildUrgentAlert(context),
      ],
    );
  }

  Widget _buildScopeCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? accentColor.withValues(alpha: 0.1)
            : AppColors.energyaLightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.isDarkMode
              ? accentColor.withValues(alpha: 0.4)
              : AppColors.energyaBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? Colors.white
                        : AppColors.energyaTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? accentColor
                        : AppColors.energyaTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? accentColor.withValues(alpha: 0.25)
                  : AppColors.energyaPrimaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: context.isDarkMode
                    ? Colors.white
                    : AppColors.energyaPrimaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantManagerCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.runningEmerald.withValues(alpha: 0.1)
            : AppColors.energyaLightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.isDarkMode
              ? AppColors.runningEmerald.withValues(alpha: 0.4)
              : AppColors.energyaBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.runningEmerald,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('plant_mgr_scope'),
              style: TextStyle(
                color: context.isDarkMode
                    ? Colors.white
                    : AppColors.energyaTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Flexible(
            child: Text(
              context.trArgs('ticket_count', {'count': allCount.toString()}),
              style: const TextStyle(
                color: AppColors.runningEmerald,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context) {
    final isElectrical = currentUser?.speciality == 'Electrical';
    final accent =
        isElectrical ? AppColors.electricBlue : AppColors.cyberCyan;

    return _buildScopeCard(
      context: context,
      icon: isElectrical ? Icons.bolt_rounded : Icons.build_circle_rounded,
      iconColor: isElectrical ? context.brandPrimary : context.brandAccent,
      title: isElectrical
          ? context.tr('tech_scope_electrical')
          : context.tr('tech_scope_mechanical'),
      subtitle: context.tr('tech_scope_sub'),
      badgeText: context.trArgs(
        'ticket_count',
        {'count': scopedCount.toString()},
      ),
      accentColor: accent,
    );
  }

  Widget _buildUrgentAlert(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.energyaAccentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.energyaAccentOrange.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.energyaAccentOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.trArgs('pending_assignments_msg', {
                'count': pendingAssignmentsCount.toString(),
              }),
              style: TextStyle(
                color: context.isDarkMode
                    ? Colors.white
                    : AppColors.energyaTextPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
