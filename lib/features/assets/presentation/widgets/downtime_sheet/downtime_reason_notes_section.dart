import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Quick reason presets chips and specific notes input field for downtime sheet.
class DowntimeReasonNotesSection extends StatelessWidget {
  final TextEditingController reasonController;
  final List<String> quickReasons;
  final ValueChanged<String> onQuickReasonSelected;

  const DowntimeReasonNotesSection({
    super.key,
    required this.reasonController,
    required this.quickReasons,
    required this.onQuickReasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. QUICK REASON CHIPS / NOTES',
          style: TextStyle(
            color: context.textMutedColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickReasons.map((reason) {
            return ActionChip(
              label: Text(reason),
              backgroundColor: context.isDarkMode
                  ? AppColors.slateCard
                  : AppColors.energyaLightSurface,
              side: BorderSide(color: context.borderColor),
              labelStyle: TextStyle(
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                fontSize: 11,
              ),
              onPressed: () => onQuickReasonSelected(reason),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: 'Enter specific downtime cause / notes...',
            hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
            filled: true,
            fillColor: context.isDarkMode
                ? AppColors.slateCard
                : AppColors.energyaLightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
        ),
      ],
    );
  }
}
