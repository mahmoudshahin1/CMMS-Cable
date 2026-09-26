import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/department_type.dart';
import '../../cubit/analytics_cubit.dart';

/// Horizontal scrollable chips to filter analytics by factory department.
class AnalyticsDepartmentFilterChips extends StatelessWidget {
  final DepartmentType? selectedDept;

  const AnalyticsDepartmentFilterChips({
    super.key,
    required this.selectedDept,
  });

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode
                    ? AppColors.electricBlue
                    : context.brandPrimary)
                : context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary)
                  : context.borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textSecondaryColor,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context: context,
            label: context.tr('all_depts_filter'),
            isSelected: selectedDept == null,
            onTap: () => context.read<AnalyticsCubit>().selectDepartment(null),
          ),
          ...DepartmentType.values.map((dept) {
            return _buildFilterChip(
              context: context,
              label: dept.localizedName(context.isArabic),
              isSelected: selectedDept == dept,
              onTap: () => context.read<AnalyticsCubit>().selectDepartment(dept),
            );
          }),
        ],
      ),
    );
  }
}
