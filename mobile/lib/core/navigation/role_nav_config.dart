import 'package:flutter/material.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/assets/presentation/screens/plant_overview_screen.dart';
import '../../features/work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../features/work_orders/presentation/screens/technician_notifications_screen.dart';
import '../../features/analytics/presentation/screens/plant_analytics_screen.dart';
import '../theme/app_colors.dart';
import '../localization/app_strings.dart';

/// Atomic model representing a single navigation tab in the app.
class RoleNavTab {
  final IconData icon;
  final String label;
  final int badgeCount;

  const RoleNavTab({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Provides role-based navigation configuration, screens, and localized tabs.
class RoleNavConfig {
  final List<Widget> screens;
  final List<RoleNavTab> tabs;

  const RoleNavConfig({
    required this.screens,
    required this.tabs,
  });

  /// Backward-compatible getter returning standard [BottomNavigationBarItem]s.
  List<BottomNavigationBarItem> get navItems => tabs.map((tab) {
        Widget iconWidget = Icon(tab.icon);
        if (tab.badgeCount > 0) {
          iconWidget = Badge(
            label: Text('${tab.badgeCount}'),
            backgroundColor: AppColors.downMaintenanceRed,
            child: iconWidget,
          );
        }
        return BottomNavigationBarItem(
          icon: iconWidget,
          label: tab.label,
        );
      }).toList();

  /// Items formatted for the desktop sidebar navigation.
  List<({IconData icon, String label})> get sidebarItems =>
      tabs.map((tab) => (icon: tab.icon, label: tab.label)).toList();

  static RoleNavConfig build(
    BuildContext context,
    UserRole role,
    int assignedCount,
  ) {
    switch (role) {
      case UserRole.maintenanceTech:
        return RoleNavConfig(
          screens: const [
            WorkOrdersListScreen(assignedOnly: true),
            TechnicianNotificationsScreen(),
          ],
          tabs: [
            RoleNavTab(
              icon: Icons.assignment_turned_in_rounded,
              label: context.tr('tab_my_tasks'),
            ),
            RoleNavTab(
              icon: Icons.notifications_active_rounded,
              label: context.tr('tab_notifications'),
              badgeCount: assignedCount,
            ),
          ],
        );

      case UserRole.operator:
        return RoleNavConfig(
          screens: const [PlantOverviewScreen(), WorkOrdersListScreen()],
          tabs: [
            RoleNavTab(
              icon: Icons.factory_rounded,
              label: context.tr('tab_factory'),
            ),
            RoleNavTab(
              icon: Icons.build_rounded,
              label: context.tr('tab_work_orders'),
            ),
          ],
        );

      case UserRole.plantManager:
        return RoleNavConfig(
          screens: const [
            PlantAnalyticsScreen(),
            PlantOverviewScreen(),
            WorkOrdersListScreen(),
          ],
          tabs: [
            RoleNavTab(
              icon: Icons.insights_rounded,
              label: context.tr('tab_executive'),
            ),
            RoleNavTab(
              icon: Icons.factory_rounded,
              label: context.tr('tab_factory'),
            ),
            RoleNavTab(
              icon: Icons.inventory_2_rounded,
              label: context.tr('tab_work_orders'),
            ),
          ],
        );

      case UserRole.maintenanceSupervisor:
      case UserRole.productionSupervisor:
        return RoleNavConfig(
          screens: const [
            PlantOverviewScreen(),
            WorkOrdersListScreen(),
            PlantAnalyticsScreen(),
          ],
          tabs: [
            RoleNavTab(
              icon: Icons.factory_rounded,
              label: context.tr('tab_factory'),
            ),
            RoleNavTab(
              icon: Icons.build_rounded,
              label: context.tr('tab_work_orders'),
            ),
            RoleNavTab(
              icon: Icons.bar_chart_rounded,
              label: context.tr('tab_analytics'),
            ),
          ],
        );
    }
  }
}
