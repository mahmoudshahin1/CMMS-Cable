import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../downtime/domain/enums/downtime_category.dart';

/// Choice chips for selecting downtime category (Breakdown, Process, Setup, etc.).
class DowntimeCategorySelector extends StatelessWidget {
  final DowntimeCategory selectedCategory;
  final ValueChanged<DowntimeCategory> onCategorySelected;

  const DowntimeCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. SELECT DOWNTIME CATEGORY',
          style: TextStyle(
            color: context.textMutedColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DowntimeCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) onCategorySelected(cat);
              },
              selectedColor: cat.isMaintenance
                  ? AppColors.downMaintenanceRed
                  : AppColors.downProcessOrange,
              backgroundColor: context.isDarkMode
                  ? AppColors.slateCard
                  : AppColors.energyaLightSurface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : context.textSecondaryColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
