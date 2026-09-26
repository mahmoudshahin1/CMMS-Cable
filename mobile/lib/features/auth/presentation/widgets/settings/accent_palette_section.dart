import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/accent_palette.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_cubit.dart';
import '../../../../../core/theme/theme_state.dart';

/// Industrial plant color palette customizer grid.
class AccentPaletteSection extends StatelessWidget {
  const AccentPaletteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final currentPalette = themeState.accentPalette;

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
                    Icons.color_lens_rounded,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('accent_color_section'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('accent_color_hint'),
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: AppPalettes.allPalettes.length,
                itemBuilder: (context, index) {
                  final palette = AppPalettes.allPalettes[index];
                  final isSelected = currentPalette.id == palette.id;

                  return GestureDetector(
                    onTap: () {
                      context.read<ThemeCubit>().setAccentPalette(palette);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primary.withValues(alpha: 0.25)
                            : (context.isDarkMode
                                ? AppColors.darkNavy
                                : AppColors.energyaLightSurface),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? palette.secondary
                              : context.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [palette.primary, palette.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.primary.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.isArabic
                                  ? palette.nameAr
                                  : palette.nameEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
