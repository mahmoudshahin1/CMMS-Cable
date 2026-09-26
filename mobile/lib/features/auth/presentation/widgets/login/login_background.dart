import 'package:flutter/material.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_colors.dart';

/// Full-screen ambient background with industrial gradients and decorative circles.
class LoginBackground extends StatelessWidget {
  final bool isDark;

  const LoginBackground({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0F1E),
                      Color(0xFF0D1B2A),
                      Color(0xFF1A1F3C),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8FAFD),
                      Color(0xFFEDF2F9),
                      Color(0xFFE2E8F0),
                    ],
                  ),
          ),
        ),
        // Decorative circle top-right
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark
                      ? AppColors.electricBlue
                      : AppColors.energyaPrimaryBlue)
                  .withValues(alpha: isDark ? 0.06 : 0.08),
            ),
          ),
        ),
        // Decorative circle bottom-left
        Positioned(
          bottom: -120,
          left: -60,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark
                      ? AppColors.cyberCyan
                      : AppColors.energyaAccentOrange)
                  .withValues(alpha: isDark ? 0.04 : 0.05),
            ),
          ),
        ),
      ],
    );
  }
}
