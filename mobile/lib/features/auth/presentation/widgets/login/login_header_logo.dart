import 'package:flutter/material.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_colors.dart';

/// Elevated logo badge displaying Energya Power Cables branding.
class LoginHeaderLogo extends StatelessWidget {
  final bool isDark;

  const LoginHeaderLogo({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.electricBlue.withValues(alpha: 0.25)
                : const Color(0xFF0C4595).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: isDark ? 2 : 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        height: 90,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Energya Power Cables',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C4595),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
