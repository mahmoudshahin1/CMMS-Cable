import 'package:flutter/material.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/assets/presentation/screens/plant_overview_screen.dart';
import '../../features/work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../features/work_orders/presentation/screens/technician_notifications_screen.dart';
import '../../features/analytics/presentation/screens/plant_analytics_screen.dart';
import '../theme/app_colors.dart';
import '../localization/app_strings.dart';

class RoleNavConfig {
  final List<Widget> screens;
  final List<BottomNavigationBarItem> navItems;
  final List<({IconData icon, String label})> sidebarItems;

  const RoleNavConfig({
    required this.screens,
    required this.navItems,
    required this.sidebarItems,
  });

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
          navItems: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_turned_in_rounded),
              label: context.tr('tab_my_tasks'),
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: assignedCount > 0,
                label: Text('$assignedCount'),
                backgroundColor: AppColors.downMaintenanceRed,
                child: const Icon(Icons.notifications_active_rounded),
              ),
              label: context.tr('tab_notifications'),
            ),
          ],
          sidebarItems: [
            (
              icon: Icons.assignment_turned_in_rounded,
              label: context.tr('tab_my_tasks'),
            ),
            (
              icon: Icons.notifications_active_rounded,
              label: context.tr('tab_notifications'),
            ),
          ],
        );

      case UserRole.operator:
        return RoleNavConfig(
          screens: const [PlantOverviewScreen(), WorkOrdersListScreen()],
          navItems: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.factory_rounded),
              label: context.tr('tab_factory'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.build_rounded),
              label: context.tr('tab_work_orders'),
            ),
          ],
          sidebarItems: [
            (icon: Icons.factory_rounded, label: context.tr('tab_factory')),
            (
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
          navItems: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.insights_rounded),
              label: context.tr('tab_executive'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.factory_rounded),
              label: context.tr('tab_factory'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_rounded),
              label: context.tr('tab_work_orders'),
            ),
          ],
          sidebarItems: [
            (
              icon: Icons.insights_rounded,
              label: context.tr('tab_executive'),
            ),
            (icon: Icons.factory_rounded, label: context.tr('tab_factory')),
            (
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
          navItems: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.factory_rounded),
              label: context.tr('tab_factory'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.build_rounded),
              label: context.tr('tab_work_orders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_rounded),
              label: context.tr('tab_analytics'),
            ),
          ],
          sidebarItems: [
            (icon: Icons.factory_rounded, label: context.tr('tab_factory')),
            (
              icon: Icons.build_rounded,
              label: context.tr('tab_work_orders'),
            ),
            (
              icon: Icons.bar_chart_rounded,
              label: context.tr('tab_analytics'),
            ),
          ],
        );
    }
  }
}
