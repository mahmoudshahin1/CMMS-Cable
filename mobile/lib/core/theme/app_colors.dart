import 'package:flutter/material.dart';

class AppColors {
  // Dark Palette (Default Industrial - PRESERVED 100% UNCHANGED)
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color slateCard = Color(0xFF1E293B);
  static const Color slateBorder = Color(0xFF334155);
  static const Color slateLight = Color(0xFF475569);

  // Official Energya Cables Visual Identity Tokens (Light Mode Reference)
  static const Color energyaPrimaryBlue = Color(0xFF0C4595); // Primary brand blue
  static const Color energyaAccentOrange = Color(0xFFF04E37); // Accent orange/red
  static const Color energyaDeepNavy = Color(0xFF082957); // Deep navy
  static const Color energyaSecondaryDeepBlue = Color(0xFF093777); // Secondary deep blue
  static const Color energyaLightBg = Color(0xFFF2F5FA); // Main app background
  static const Color energyaLightSurface = Color(0xFFE1E8F2); // Secondary surface
  static const Color energyaWhite = Color(0xFFFFFFFF); // Clean white card surface
  static const Color energyaTextPrimary = Color(0xFF212529); // Primary text
  static const Color energyaTextMuted = Color(0xFF6C757D); // Muted text
  static const Color energyaBorder = Color(0xFFE1E8F2); // 1px borders

  // Light Palette (Official Energya Cables Light Mode)
  static const Color lightBg = energyaLightBg;
  static const Color lightCard = energyaWhite;
  static const Color lightBorder = energyaBorder;
  static const Color lightTextPrimary = energyaTextPrimary;
  static const Color lightTextSecondary = energyaTextMuted;
  static const Color lightTextMuted = energyaTextMuted;

  // Accents (Consistent across themes)
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color cyberCyan = Color(0xFF06B6D4);

  // Machine Status Colors (Vibrant & High-Contrast)
  static const Color runningEmerald = Color(0xFF10B981);
  static const Color idleAmber = Color(0xFFF59E0B);
  static const Color downProcessOrange = Color(0xFFF97316);
  static const Color downMaintenanceRed = Color(0xFFEF4444);
  static const Color underRepairPurple = Color(0xFF8B5CF6);
  static const Color subduedViolet = Color(0xFF8B5CF6);

  // Text Colors (Dark Mode Defaults)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFF3B82F6);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityCritical = Color(0xFFEF4444);
}

extension AppThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isLightMode => !isDarkMode;

  Color get scaffoldBg =>
      isDarkMode ? AppColors.darkNavy : AppColors.lightBg;

  Color get cardBg =>
      isDarkMode ? AppColors.slateCard : AppColors.lightCard;

  Color get borderColor =>
      isDarkMode ? AppColors.slateBorder : AppColors.lightBorder;

  Color get textPrimaryColor =>
      isDarkMode ? AppColors.textPrimary : AppColors.lightTextPrimary;

  Color get textSecondaryColor =>
      isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary;

  Color get textMutedColor =>
      isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;

  Color get brandPrimary =>
      isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue;

  Color get brandAccent =>
      isDarkMode ? AppColors.cyberCyan : AppColors.energyaAccentOrange;

  Color get brandNavy =>
      isDarkMode ? AppColors.darkNavy : AppColors.energyaDeepNavy;

  Color get surfaceContainer =>
      isDarkMode ? AppColors.slateCard : AppColors.energyaLightSurface;
}

