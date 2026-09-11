import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';
import '../../features/work_orders/presentation/cubit/work_order_state.dart';
import '../../features/work_orders/domain/enums/work_order_status.dart';
import '../../features/assets/presentation/screens/plant_overview_screen.dart';
import '../../features/work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../features/work_orders/presentation/screens/technician_notifications_screen.dart';
import '../../features/analytics/presentation/screens/plant_analytics_screen.dart';
import '../theme/app_colors.dart';
import '../localization/app_strings.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/desktop_topbar.dart';

/// Root navigation shell that switches between mobile bottom-nav
/// and desktop sidebar layouts based on screen width.
///
/// Builds role-specific screen lists and navigation items from the
/// currently authenticated [UserRole].
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  UserRole? _lastRole;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is Authenticated ? authState.user : null;
        final currentRole =
            currentUser?.role ?? UserRole.maintenanceSupervisor;

        // Reset tab index if role changed to avoid index out of range
        if (_lastRole != currentRole) {
          _lastRole = currentRole;
          _currentIndex = 0;
        }

        return BlocBuilder<WorkOrderCubit, WorkOrderState>(
          builder: (context, woState) {
            final assignedCount = _countAssignedOrders(woState, currentUser);
            final config = _buildRoleConfig(
              context,
              currentRole,
              assignedCount,
            );

            final safeIndex = _currentIndex < config.screens.length
                ? _currentIndex
                : 0;

            final isWideScreen =
                MediaQuery.of(context).size.width >= 850;

            if (isWideScreen) {
              return _buildDesktopLayout(
                context,
                config,
                safeIndex,
                currentUser,
                currentRole,
              );
            }

            return _buildMobileLayout(config, safeIndex);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Count assigned work orders for badge
  // ---------------------------------------------------------------------------
  int _countAssignedOrders(WorkOrderState woState, dynamic currentUser) {
    if (woState is WorkOrderLoaded && currentUser != null) {
      return woState.allWorkOrders
          .where(
            (wo) =>
                wo.assignedToTechnicianId == currentUser.id &&
                wo.status == WorkOrderStatus.assigned,
          )
          .length;
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Desktop Layout: Sidebar + TopBar + Content
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout(
    BuildContext context,
    _RoleNavConfig config,
    int safeIndex,
    dynamic currentUser,
    UserRole currentRole,
  ) {
    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(
            sidebarItems: config.sidebarItems,
            selectedIndex: safeIndex,
            onItemSelected: (i) => setState(() => _currentIndex = i),
            currentUser: currentUser,
            currentRole: currentRole,
          ),
          Expanded(
            child: Column(
              children: [
                DesktopTopbar(
                  currentPageLabel: config.sidebarItems[safeIndex].label,
                ),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: config.screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile Layout: Bottom Navigation Bar
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(_RoleNavConfig config, int safeIndex) {
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: config.screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: config.navItems,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Role-based Navigation Configuration Factory
  // ---------------------------------------------------------------------------
  _RoleNavConfig _buildRoleConfig(
    BuildContext context,
    UserRole role,
    int assignedCount,
  ) {
    switch (role) {
      case UserRole.maintenanceTech:
        return _RoleNavConfig(
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
        return _RoleNavConfig(
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
        return _RoleNavConfig(
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
        return _RoleNavConfig(
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

// ---------------------------------------------------------------------------
// Internal data class for role-based navigation configuration
// ---------------------------------------------------------------------------
class _RoleNavConfig {
  final List<Widget> screens;
  final List<BottomNavigationBarItem> navItems;
  final List<({IconData icon, String label})> sidebarItems;

  const _RoleNavConfig({
    required this.screens,
    required this.navItems,
    required this.sidebarItems,
  });
}
