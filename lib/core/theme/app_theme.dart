import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'dark_theme_builder.dart';
import 'light_theme_builder.dart';

class AppTheme {
  static ThemeData getDarkTheme({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.electricBlue,
    Color secondaryColor = AppColors.cyberCyan,
  }) {
    return DarkThemeBuilder.build(
      locale: locale,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
  }

  static ThemeData getLightTheme({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.energyaPrimaryBlue,
    Color secondaryColor = AppColors.energyaAccentOrange,
  }) {
    return LightThemeBuilder.build(
      locale: locale,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
  }

  static ThemeData get industrialDarkTheme => getDarkTheme();
  static ThemeData get industrialLightTheme => getLightTheme();
}
