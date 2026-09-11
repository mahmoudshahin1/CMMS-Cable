import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Quick fault presets chips for cable plant common breakdowns.
class CreateRequestQuickPresetsSection extends StatelessWidget {
  final List<String> quickFaults;
  final ValueChanged<String> onFaultSelected;

  const CreateRequestQuickPresetsSection({
    super.key,
    required this.quickFaults,
    required this.onFaultSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on_rounded,
              size: 16,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('quick_presets_step'),
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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickFaults.map((fault) {
            return ActionChip(
              label: Text(fault),
              backgroundColor: context.cardBg,
              side: BorderSide(color: context.borderColor),
              labelStyle: TextStyle(
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                fontSize: 11,
              ),
              onPressed: () => onFaultSelected(fault),
            );
          }).toList(),
        ),
      ],
    );
  }
}
