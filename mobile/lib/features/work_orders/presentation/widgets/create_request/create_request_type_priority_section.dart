import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/priority.dart';
import '../../../domain/enums/work_order_type.dart';

/// Request type selector and priority chips for new work order.
class CreateRequestTypePrioritySection extends StatelessWidget {
  final WorkOrderType selectedType;
  final ValueChanged<WorkOrderType> onTypeChanged;
  final Priority selectedPriority;
  final ValueChanged<Priority> onPriorityChanged;

  const CreateRequestTypePrioritySection({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.critical:
        return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag_rounded,
              size: 16,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('type_priority_step'),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<WorkOrderType>(
          initialValue: selectedType,
          decoration: InputDecoration(
            labelText: context.tr('request_type_label'),
            filled: true,
            fillColor: context.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dropdownColor: context.cardBg,
          items: WorkOrderType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(
                t.localizedName(context.isArabic),
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onTypeChanged(val);
          },
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('severity_priority_label'),
          style: TextStyle(color: context.textMutedColor, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: Priority.values.map((p) {
            final isSelected = selectedPriority == p;
            final pColor = _priorityColor(p);

            return ChoiceChip(
              label: Text(p.localizedName(context.isArabic).toUpperCase()),
              selected: isSelected,
              selectedColor: pColor.withValues(alpha: 0.25),
              backgroundColor: context.cardBg,
              side: BorderSide(
                color: isSelected ? pColor : context.borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
              labelStyle: TextStyle(
                color: isSelected ? pColor : context.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
              onSelected: (selected) {
                if (selected) onPriorityChanged(p);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
