import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_model.dart';

/// Top header banner showing technician name, speciality, and tasks status badge.
class TechnicianGreetingCard extends StatelessWidget {
  final UserModel currentUser;
  final int newAssignmentsCount;

  const TechnicianGreetingCard({
    super.key,
    required this.currentUser,
    required this.newAssignmentsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary)
              .withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary)
                .withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary)
                .withValues(alpha: 0.15),
            child: Icon(
              Icons.handyman_rounded,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.name,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.trArgs('maint_dept_speciality', {
                    'spec': currentUser.speciality ??
                        context.tr('maint_tech_default'),
                  }),
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: newAssignmentsCount > 0
                  ? AppColors.downMaintenanceRed.withValues(alpha: 0.2)
                  : AppColors.runningEmerald.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: newAssignmentsCount > 0
                    ? AppColors.downMaintenanceRed
                    : AppColors.runningEmerald,
              ),
            ),
            child: Text(
              newAssignmentsCount > 0
                  ? context.trArgs('new_tasks_badge', {
                      'count': '$newAssignmentsCount',
                    })
                  : context.tr('ready_for_work'),
              style: TextStyle(
                color: newAssignmentsCount > 0
                    ? AppColors.downMaintenanceRed
                    : AppColors.runningEmerald,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
