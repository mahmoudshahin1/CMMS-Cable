import 'package:flutter/material.dart';
import '../../features/assets/domain/enums/department_type.dart';
import '../theme/app_colors.dart';
import '../localization/app_strings.dart';

class DepartmentChipBar extends StatelessWidget {
  final DepartmentType? selectedDepartment;
  final ValueChanged<DepartmentType?> onDepartmentSelected;
  final List<DepartmentType>? availableDepartments;
  final bool showAllOption;

  const DepartmentChipBar({
    super.key,
    required this.selectedDepartment,
    required this.onDepartmentSelected,
    this.availableDepartments,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final depts = availableDepartments ?? DepartmentType.values;

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption)
            _buildChip(
              context: context,
              label: context.tr('all_departments'),
              isSelected: selectedDepartment == null,
              onTap: () => onDepartmentSelected(null),
            ),
          ...depts.map((dept) {
            final isSingleScope = !showAllOption && depts.length == 1;
            return _buildChip(
              context: context,
              label: dept.localizedName(context.isArabic),
              isSelected: selectedDepartment == dept || isSingleScope,
              onTap: () => onDepartmentSelected(dept),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue)
                : context.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaPrimaryBlue)
                  : context.borderColor,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (context.isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue)
                          .withValues(alpha: context.isDarkMode ? 0.4 : 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textPrimaryColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),

      ),
    );
  }
}
