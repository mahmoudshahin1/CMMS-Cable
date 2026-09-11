import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../domain/models/user_model.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/enums/app_permission.dart';
import '../widgets/switch_persona_bottom_sheet.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../../core/theme/accent_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is Authenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('settings_title')),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. User Personal Information Card
              if (currentUser != null) ...[
                _buildUserProfileCard(context, currentUser),
                const SizedBox(height: 16),
                _buildPermissionsCard(context, currentUser),
                const SizedBox(height: 20),
              ],

              // 2. Theme & Appearance
              _buildAppearanceSection(context),
              const SizedBox(height: 20),

              // 3. Accent Color Customization
              _buildAccentColorSection(context),
              const SizedBox(height: 20),

              // 4. Language Selection
              _buildLanguageSection(context),
              const SizedBox(height: 20),

              // 5. System Info
              _buildSystemInfoCard(context),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserProfileCard(BuildContext context, UserModel user) {
    final roleColor = user.role.roleColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roleColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor.withValues(alpha: 0.2),
                child: Icon(user.role.icon, color: roleColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: roleColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            user.role.badgeTitle,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (user.department != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.slateBorder
                                  : AppColors.energyaLightSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Text(
                              user.department!.name.toUpperCase(),
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (user.speciality != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (context.isDarkMode
                                      ? AppColors.cyberCyan
                                      : context.brandPrimary)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.speciality!,
                              style: TextStyle(
                                color: context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: context.borderColor.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                context.tr('current_shift_label'),
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => SwitchPersonaBottomSheet.show(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  side: BorderSide(
                    color: (context.isDarkMode
                            ? AppColors.cyberCyan
                            : context.brandPrimary)
                        .withValues(alpha: 0.6),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text(
                  context.tr('switch_account'),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(BuildContext context, UserModel user) {
    final permissions = <String>[];
    final authCubit = context.read<AuthCubit>();

    if (authCubit.can(AppPermission.logDowntime)) {
      permissions.add(context.tr('perm_log_downtime'));
    }
    if (authCubit.can(AppPermission.assignTechnician)) {
      permissions.add(context.tr('perm_assign_tech'));
    }
    if (authCubit.can(AppPermission.startRepair)) {
      permissions.add(context.tr('perm_start_repair'));
    }
    if (authCubit.can(AppPermission.addSpareParts)) {
      permissions.add(context.tr('perm_spare_parts'));
    }
    if (authCubit.can(AppPermission.completeRepair)) {
      permissions.add(context.tr('perm_complete_repair'));
    }
    if (authCubit.can(AppPermission.confirmTestRun)) {
      permissions.add(context.tr('perm_confirm_test'));
    }
    if (authCubit.can(AppPermission.reclassifyDowntime)) {
      permissions.add(context.tr('perm_reclassify'));
    }
    if (authCubit.can(AppPermission.approveAndClose)) {
      permissions.add(context.tr('perm_approve_close'));
    }
    if (authCubit.can(AppPermission.viewAnalytics)) {
      permissions.add(context.tr('perm_view_analytics'));
    }

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
              Icon(Icons.verified_user_rounded,
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  size: 18),
              const SizedBox(width: 8),
              Text(
                context.tr('permissions_title'),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: permissions.map((p) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkNavy
                      : AppColors.energyaLightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: context.borderColor.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.runningEmerald, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
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
                  Icon(Icons.palette_outlined,
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      size: 18),
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

  Widget _buildAccentColorSection(BuildContext context) {
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
                  Icon(Icons.color_lens_rounded,
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      size: 18),
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
                style: TextStyle(color: context.textSecondaryColor, fontSize: 11.5),
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
                          horizontal: 10, vertical: 8),
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
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.isArabic ? palette.nameAr : palette.nameEn,
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

  Widget _buildLanguageSection(BuildContext context) {
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
                  Icon(Icons.language_rounded,
                      color: context.isDarkMode
                          ? AppColors.cyberCyan
                          : context.brandPrimary,
                      size: 18),
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
                      onTap: () =>
                          context.read<LocaleCubit>().setLocale(const Locale('ar')),
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
                      onTap: () =>
                          context.read<LocaleCubit>().setLocale(const Locale('en')),
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

  Widget _buildSystemInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: context.textMutedColor, size: 18),
              const SizedBox(width: 8),
              Text(
                context.tr('app_version'),
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'v2.4.0 (Enterprise)',
                style: TextStyle(
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.offline_pin_rounded,
                  color: AppColors.runningEmerald, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('hive_db_active'),
                  style: TextStyle(color: context.textMutedColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business_rounded,
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('company_label'),
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}