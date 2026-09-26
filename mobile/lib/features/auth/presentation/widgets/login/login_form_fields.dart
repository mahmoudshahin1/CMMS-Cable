import 'package:flutter/material.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_colors.dart';

/// Styled input field label for authentication forms.
class LoginFormLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const LoginFormLabel({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
        color: isDark ? AppColors.textSecondary : const Color(0xFF334155),
      ),
    );
  }
}

/// Unified input decoration builder for login text form fields.
class LoginFormInputDecoration {
  static InputDecoration build({
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.textMuted.withValues(alpha: 0.45)
            : const Color(0xFF94A3B8),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.darkNavy : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.slateBorder : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.slateBorder.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.electricBlue : const Color(0xFF0C4595),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.downMaintenanceRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.downMaintenanceRed,
          width: 1.8,
        ),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        color: AppColors.downMaintenanceRed,
      ),
    );
  }
}
