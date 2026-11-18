import 'package:flutter/material.dart';
import 'package:nav_bar/nav_bar.dart';
import '../role_nav_config.dart';
import '../../theme/app_colors.dart';

/// Compact animated bottom navigation bar powered by nav_bar 0.1.1.
/// Floating pod carries the "Current & Strand" brand language: the selected
/// tab glows with the app's own brand-accent color (same
/// context.brandAccent used everywhere else -- orange in light mode, cyan
/// in dark mode) instead of a generic unbranded cyan/slate theme.
class AnimatedBottomNavBar extends StatelessWidget {
  final List<RoleNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AnimatedBottomNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = context.brandAccent;
    final podBgColor = context.brandNavy;
    const inactiveColor = Color(0xFF94A3B8); // High-contrast Slate

    final glowGradient = LinearGradient(
      colors: [
        activeColor.withValues(alpha: 0.55),
        activeColor,
        activeColor.withValues(alpha: 0.55),
      ],
    );

    final futuristicTheme = FuturisticTheme(
      name: 'EnergyaCurrent',
      glowGradient: glowGradient,
      accentColor: activeColor,
      baseColor: podBgColor,
      particleColor: activeColor,
      backgroundColor: podBgColor,
      customColors: {
        'baseColor': podBgColor,
        'borderColor': activeColor.withValues(alpha: 0.4),
        'shadowColor': const Color(0x99000000),
        'glowColor': activeColor.withValues(alpha: 0.4),
      },
    );

    return SizedBox(
      height: 72,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 80,
          child: FuturisticNavBar(
            selectedIndex: selectedIndex,
            onItemSelected: onTabSelected,
            items: tabs.asMap().entries.map((entry) {
              final idx = entry.key;
              final tab = entry.value;
              final isSelected = idx == selectedIndex;
              final color = isSelected ? activeColor : inactiveColor;

              Widget iconWidget = Icon(tab.icon, size: 22, color: color);
              if (tab.badgeCount > 0) {
                iconWidget = Badge(
                  label: Text('${tab.badgeCount}'),
                  backgroundColor: const Color(0xFFEF4444),
                  child: iconWidget,
                );
              }

              return NavBarItem(
                icon: tab.icon,
                label: tab.label,
                customIcon: iconWidget,
                customLabel: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                hasNotification: tab.badgeCount > 0,
                notificationCount: tab.badgeCount,
              );
            }).toList(),
            style: NavBarStyle.floating,
            theme: futuristicTheme,
            showGlow: true,
            showLiquid: true,
            iconSize: 22.0,
            iconLabelSpacing: 3.0,
            animationDuration: const Duration(milliseconds: 350),
          ),
        ),
      ),
    );
  }
}
