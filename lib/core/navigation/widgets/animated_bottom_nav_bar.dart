import 'package:flutter/material.dart';
import 'package:nav_bar/nav_bar.dart';
import '../role_nav_config.dart';

/// Compact animated bottom navigation bar powered by nav_bar 0.1.1.
/// Features a high-contrast Midnight Slate floating pod with glowing accents.
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
    const activeColor = Color(0xFF38BDF8); // Electric Sky Blue
    const inactiveColor = Color(0xFF94A3B8); // High-contrast Slate
    const podBgColor = Color(0xFF0F172A); // Midnight Slate

    final futuristicTheme = FuturisticTheme(
      name: 'MidnightCable',
      glowGradient: const LinearGradient(
        colors: [
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ),
      accentColor: activeColor,
      baseColor: podBgColor,
      particleColor: activeColor,
      backgroundColor: podBgColor,
      customColors: const {
        'baseColor': podBgColor,
        'borderColor': Color(0x6638BDF8),
        'shadowColor': Color(0x99000000),
        'glowColor': Color(0x6638BDF8),
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
