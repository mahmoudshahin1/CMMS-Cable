import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/enums/user_role.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../auth/presentation/cubit/auth_state.dart';
import '../../../domain/enums/department_type.dart';

/// Department scope restriction banner or technician speciality badge for plant overview.
class PlantDepartmentScopeBanner extends StatelessWidget {
  const PlantDepartmentScopeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is Authenticated ? authState.user : null;
        final userDept = currentUser?.department;
        final isPlantManager =
            currentUser?.role == UserRole.plantManager;
        final isTech =
            currentUser?.role == UserRole.maintenanceTech;
        final isOperator =
            currentUser?.role == UserRole.operator;
        final hasDeptScope =
            (userDept != null && !isPlantManager && !isTech) || isOperator;

        if (isTech) {
          final isElec = currentUser?.speciality == 'Electrical';
          final color = isElec ? context.brandPrimary : context.brandAccent;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? color.withValues(alpha: 0.1)
                  : AppColors.energyaLightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.isDarkMode
                    ? color.withValues(alpha: 0.35)
                    : AppColors.energyaBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isElec ? Icons.bolt_rounded : Icons.build_circle_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      isElec ? 'tech_banner_elec' : 'tech_banner_mech',
                    ),
                    style: TextStyle(
                      color: context.isDarkMode
                          ? Colors.white
                          : AppColors.energyaTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  currentUser?.email ?? '',
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          );
        }

        if (!hasDeptScope) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? AppColors.cyberCyan.withValues(alpha: 0.1)
                : AppColors.energyaLightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.isDarkMode
                  ? AppColors.cyberCyan.withValues(alpha: 0.35)
                  : AppColors.energyaBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : AppColors.energyaPrimaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.trArgs('dept_machines_scope', {
                    'dept': userDept?.localizedName(context.isArabic) ?? '',
                  }),
                  style: TextStyle(
                    color: context.isDarkMode
                        ? Colors.white
                        : AppColors.energyaTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                currentUser?.email ?? '',
                style: TextStyle(
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : AppColors.energyaPrimaryBlue,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
