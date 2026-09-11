import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Form section for logging root cause analysis and actions taken during repair.
class RootCauseMaintenanceSection extends StatelessWidget {
  final TextEditingController rootCauseController;
  final TextEditingController actionsTakenController;
  final bool isEnabled;

  const RootCauseMaintenanceSection({
    super.key,
    required this.rootCauseController,
    required this.actionsTakenController,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROOT CAUSE & MAINTENANCE ACTIONS',
          style: TextStyle(
            color: context.isDarkMode
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Root Cause Breakdown Analysis',
          style: TextStyle(
            color: context.brandPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: rootCauseController,
          enabled: isEnabled,
          style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            hintText: 'Enter root cause breakdown analysis...',
            hintStyle: TextStyle(color: context.textMutedColor),
            filled: true,
            fillColor: context.cardBg,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.borderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.brandPrimary),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Actions Taken & Repair Steps',
          style: TextStyle(
            color: context.brandPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: actionsTakenController,
          enabled: isEnabled,
          style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            hintText: 'Enter repair steps performed...',
            hintStyle: TextStyle(color: context.textMutedColor),
            filled: true,
            fillColor: context.cardBg,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.borderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: context.brandPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
