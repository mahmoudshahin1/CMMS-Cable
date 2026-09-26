import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/department_type.dart';
import '../../../../assets/domain/models/machine_model.dart';

/// Dropdown selector and department scope banner for choosing target machine.
class CreateRequestMachineSelector extends StatelessWidget {
  final List<MachineModel> selectableMachines;
  final String? selectedMachineId;
  final ValueChanged<String?> onMachineChanged;
  final DepartmentType? userDept;
  final bool hasDeptScope;

  const CreateRequestMachineSelector({
    super.key,
    required this.selectableMachines,
    required this.selectedMachineId,
    required this.onMachineChanged,
    required this.userDept,
    required this.hasDeptScope,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.factory_rounded,
              size: 16,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('select_machine'),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasDeptScope && userDept != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.trArgs('dept_machines_restricted', {
                      'dept': userDept!.localizedName(context.isArabic),
                    }),
                    style: TextStyle(
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: context.cardBg,
              hint: Text(
                context.tr('select_machine_hint'),
                style: TextStyle(color: context.textMutedColor, fontSize: 13),
              ),
              value: selectedMachineId,
              items: selectableMachines.map((m) {
                return DropdownMenuItem<String>(
                  value: m.id,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkNavy
                              : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Text(
                          m.code,
                          style: TextStyle(
                            color: context.isDarkMode
                                ? AppColors.cyberCyan
                                : context.brandPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m.name} (${m.department.localizedName(context.isArabic)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onMachineChanged,
            ),
          ),
        ),
      ],
    );
  }
}
