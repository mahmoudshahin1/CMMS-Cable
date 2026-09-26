import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/app_permission.dart';
import '../../../domain/models/user_model.dart';
import '../../cubit/auth_cubit.dart';

/// Displays the active RBAC capabilities granted to the current user.
class UserPermissionsCard extends StatelessWidget {
  final UserModel user;

  const UserPermissionsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final permissions = <String>[];
    final authCubit = context.read<AuthCubit>();

    if (authCubit.can(AppPermission.logDowntime)) {
      permissions.add(context.tr('perm_log_downtime'));
    }
    if (authCubit.can(AppPermission.assignTechnician)) {
      permissions.add(context.tr('perm_assign_tech'));
    }
    if (authCubit.can(AppPermission.startRepair)) {
      permissions.add(context.tr('perm_start_repair'));
    }
    if (authCubit.can(AppPermission.addSpareParts)) {
      permissions.add(context.tr('perm_spare_parts'));
    }
    if (authCubit.can(AppPermission.completeRepair)) {
      permissions.add(context.tr('perm_complete_repair'));
    }
    if (authCubit.can(AppPermission.confirmTestRun)) {
      permissions.add(context.tr('perm_confirm_test'));
    }
    if (authCubit.can(AppPermission.reclassifyDowntime)) {
      permissions.add(context.tr('perm_reclassify'));
    }
    if (authCubit.can(AppPermission.approveAndClose)) {
      permissions.add(context.tr('perm_approve_close'));
    }
    if (authCubit.can(AppPermission.viewAnalytics)) {
      permissions.add(context.tr('perm_view_analytics'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('permissions_title'),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions.map((p) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkNavy
                      : AppColors.energyaLightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.runningEmerald,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
