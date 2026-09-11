import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme({
    required Brightness brightness,
    required Locale locale,
    required Color textColor,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final fontTheme = locale.languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(baseTextTheme)
        : GoogleFonts.interTextTheme(baseTextTheme);

    return fontTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }

  static ThemeData getDarkTheme({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.electricBlue,
    Color secondaryColor = AppColors.cyberCyan,
  }) {
    final textTheme = _buildTextTheme(
      brightness: Brightness.dark,
      locale: locale,
      textColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkNavy,
      textTheme: textTheme,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppColors.slateCard,
        error: AppColors.downMaintenanceRed,
        onSurface: AppColors.textPrimary,
        outline: AppColors.slateBorder,
        surfaceContainerHighest: AppColors.slateCard,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          inherit: false,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.slateCard,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.slateBorder, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slateCard,
        disabledColor: AppColors.slateBorder,
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 12,
          inherit: false,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 12,
          inherit: false,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.slateBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.slateCard,
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
              inherit: false,
            );
          }
          return textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 11.5,
            inherit: false,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: secondaryColor);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.slateCard,
        selectedItemColor: secondaryColor,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          inherit: false,
        ),
        unselectedLabelStyle: textTheme.bodySmall?.copyWith(
          inherit: false,
        ),
        elevation: 8,
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
          foregroundColor: secondaryColor,
          side: const BorderSide(color: AppColors.slateBorder),
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
          foregroundColor: secondaryColor,
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
        color: AppColors.slateBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData getLightTheme({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.energyaPrimaryBlue,
    Color secondaryColor = AppColors.energyaAccentOrange,
  }) {
    final textTheme = _buildTextTheme(
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

  static ThemeData get industrialDarkTheme => getDarkTheme();
  static ThemeData get industrialLightTheme => getLightTheme();
}
