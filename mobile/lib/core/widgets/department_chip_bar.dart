import 'package:flutter/material.dart';
import '../../features/assets/domain/enums/department_type.dart';
import '../theme/app_colors.dart';
import '../localization/app_strings.dart';

/// Purely decorative stroke icon per manufacturing stage -- the department
/// names/codes themselves are untouched (see DepartmentType).
IconData _iconForDepartment(DepartmentType dept) {
  switch (dept) {
    case DepartmentType.drawing:
      return Icons.linear_scale_rounded;
    case DepartmentType.stranding:
      return Icons.sync_alt_rounded;
    case DepartmentType.ccv:
      return Icons.local_fire_department_rounded;
    case DepartmentType.extrusion:
      return Icons.compress_rounded;
    case DepartmentType.assembly:
      return Icons.build_circle_outlined;
    case DepartmentType.screening:
      return Icons.layers_rounded;
    case DepartmentType.armouring:
      return Icons.shield_rounded;
    case DepartmentType.rewinding:
      return Icons.all_inclusive_rounded;
  }
}

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
              icon: Icons.blur_circular_rounded,
              isSelected: selectedDepartment == null,
              onTap: () => onDepartmentSelected(null),
            ),
          ...depts.map((dept) {
            final isSingleScope = !showAllOption && depts.length == 1;
            return _buildChip(
              context: context,
              label: dept.localizedName(context.isArabic),
              icon: _iconForDepartment(dept),
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedColor =
        context.isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaPrimaryBlue)
                  : context.borderColor,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: context.isDarkMode ? 0.4 : 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : context.textMutedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
