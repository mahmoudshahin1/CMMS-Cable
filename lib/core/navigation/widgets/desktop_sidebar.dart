import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../localization/app_strings.dart';
import '../../widgets/energya_logo.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../features/auth/presentation/widgets/switch_persona_bottom_sheet.dart';
import '../../../features/auth/presentation/screens/settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../localization/locale_cubit.dart';
import '../../theme/theme_cubit.dart';

/// Industrial Energya Cables desktop sidebar with navigation, branding,
/// and user profile footer. Designed for wide-screen layouts (≥850px).
class DesktopSidebar extends StatelessWidget {
  final List<({IconData icon, String label})> sidebarItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final UserModel? currentUser;
  final UserRole currentRole;

  const DesktopSidebar({
    super.key,
    required this.sidebarItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.currentUser,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.energyaDeepNavy,
            AppColors.energyaSecondaryDeepBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: _SidebarNavList(
              items: sidebarItems,
              selectedIndex: selectedIndex,
              onItemSelected: onItemSelected,
            ),
          ),
          _SidebarFooter(
            currentUser: currentUser,
            currentRole: currentRole,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar Header — Logo & Industrial Branding
// ---------------------------------------------------------------------------
class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.energyaDeepNavy,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const EnergyaLogo(height: 32),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.energyaAccentOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'CABLE OPS CMMS • 10TH OF RAMADAN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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

// ---------------------------------------------------------------------------
// Sidebar Navigation List
// ---------------------------------------------------------------------------
class _SidebarNavList extends StatelessWidget {
  final List<({IconData icon, String label})> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _SidebarNavList({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIndex == index;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onItemSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.energyaAccentOrange.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppColors.energyaAccentOrange
                          .withValues(alpha: 0.6),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? AppColors.energyaAccentOrange
                      : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.energyaAccentOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar Footer — User Profile & Quick Actions
// ---------------------------------------------------------------------------
class _SidebarFooter extends StatelessWidget {
  final UserModel? currentUser;
  final UserRole currentRole;

  const _SidebarFooter({
    required this.currentUser,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.energyaDeepNavy,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => SwitchPersonaBottomSheet.show(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      currentRole.roleColor.withValues(alpha: 0.25),
                  child: Icon(
                    currentRole.icon,
                    color: currentRole.roleColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name ?? context.tr('shift_manager'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentRole.badgeTitle,
                        style: TextStyle(
                          color: currentRole.roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.swap_vert_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.language_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('lang_toggle'),
                onPressed: () =>
                    context.read<LocaleCubit>().toggleLanguage(),
              ),
              IconButton(
                icon: Icon(
                  context.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('theme_toggle'),
                onPressed: () =>
                    context.read<ThemeCubit>().toggleTheme(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('settings_title'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
