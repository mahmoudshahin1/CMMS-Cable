import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_theme_factory.dart';

class LightThemeBuilder {
  static ThemeData build({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.energyaPrimaryBlue,
    Color secondaryColor = AppColors.energyaAccentOrange,
  }) {
    final textTheme = TextThemeFactory.buildTextTheme(
      brightness: Brightness.light,
      locale: locale,
      textColor: AppColors.energyaTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.energyaLightBg,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppColors.energyaWhite,
        error: AppColors.downMaintenanceRed,
        onSurface: AppColors.energyaTextPrimary,
        outline: AppColors.energyaBorder,
        surfaceContainerHighest: AppColors.energyaLightSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.energyaWhite,
        foregroundColor: AppColors.energyaTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.energyaTextPrimary),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.energyaTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          inherit: false,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.energyaWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.energyaBorder, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.energyaWhite,
        disabledColor: AppColors.energyaBorder,
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.energyaTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          inherit: false,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          inherit: false,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.energyaBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.energyaWhite,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.bodySmall?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              inherit: false,
            );
          }
          return textTheme.bodySmall?.copyWith(
            color: AppColors.energyaTextMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11.5,
            inherit: false,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: AppColors.energyaTextMuted);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.energyaWhite,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.energyaTextMuted,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          inherit: false,
        ),
        unselectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          inherit: false,
        ),
        elevation: 6,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: AppColors.energyaBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.energyaBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
