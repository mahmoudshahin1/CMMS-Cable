import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/localization/locale_cubit.dart';
import '../../../../../core/theme/app_colors.dart';

/// Language switcher card (Arabic / English).
class LanguageSelectorSection extends StatelessWidget {
  const LanguageSelectorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isArabic = locale.languageCode == 'ar';

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
                    Icons.language_rounded,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('language_section'),
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
                          .read<LocaleCubit>()
                          .setLocale(const Locale('ar')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isArabic
                              ? (context.isDarkMode
                                  ? AppColors.electricBlue
                                  : context.brandPrimary)
                              : (context.isDarkMode
                                  ? AppColors.darkNavy
                                  : AppColors.energyaLightSurface),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isArabic
                                ? (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                : context.borderColor,
                          ),
                        ),
                        child: Text(
                          context.tr('lang_arabic_label'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isArabic
                                ? Colors.white
                                : (context.isDarkMode
                                    ? Colors.white70
                                    : context.textSecondaryColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context
                          .read<LocaleCubit>()
                          .setLocale(const Locale('en')),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isArabic
                              ? (context.isDarkMode
                                  ? AppColors.electricBlue
                                  : context.brandPrimary)
                              : (context.isDarkMode
                                  ? AppColors.darkNavy
                                  : AppColors.energyaLightSurface),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !isArabic
                                ? (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                : context.borderColor,
                          ),
                        ),
                        child: Text(
                          context.tr('lang_english_label'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !isArabic
                                ? Colors.white
                                : (context.isDarkMode
                                    ? Colors.white70
                                    : context.textSecondaryColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
