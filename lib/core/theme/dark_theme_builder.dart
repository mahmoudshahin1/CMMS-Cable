import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_theme_factory.dart';

class DarkThemeBuilder {
  static ThemeData build({
    Locale locale = const Locale('ar'),
    Color primaryColor = AppColors.electricBlue,
    Color secondaryColor = AppColors.cyberCyan,
  }) {
    final textTheme = TextThemeFactory.buildTextTheme(
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
}
