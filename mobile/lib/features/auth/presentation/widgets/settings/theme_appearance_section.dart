import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_cubit.dart';
import '../../../../../core/theme/theme_state.dart';

/// Dark/Light mode appearance selector card.
class ThemeAppearanceSection extends StatelessWidget {
  const ThemeAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.isDark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('appearance_section'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.dark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (context.isDarkMode
                                  ? AppColors.electricBlue
                                  : context.brandPrimary)
                              : (context.isDarkMode
                                  ? AppColors.darkNavy
                                  : AppColors.energyaLightSurface),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                : context.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dark_mode_rounded,
                              color: isDark
                                  ? Colors.white
                                  : (context.isDarkMode
                                      ? Colors.white60
                                      : context.textMutedColor),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('dark_mode'),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : (context.isDarkMode
                                        ? Colors.white70
                                        : context.textSecondaryColor),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context
                          .read<ThemeCubit>()
                          .setThemeMode(ThemeMode.light),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isDark
                              ? (context.isDarkMode
                                  ? AppColors.electricBlue
                                  : context.brandPrimary)
                              : (context.isDarkMode
                                  ? AppColors.darkNavy
                                  : AppColors.energyaLightSurface),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isDark
                                ? (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                : context.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.light_mode_rounded,
                              color: !isDark
                                  ? Colors.white
                                  : (context.isDarkMode
                                      ? Colors.white60
                                      : context.textMutedColor),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('light_mode'),
                              style: TextStyle(
                                color: !isDark
                                    ? Colors.white
                                    : (context.isDarkMode
                                        ? Colors.white70
                                        : context.textSecondaryColor),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
