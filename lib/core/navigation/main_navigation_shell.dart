import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/domain/enums/user_role.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';
import '../../features/work_orders/presentation/cubit/work_order_state.dart';
import '../../features/work_orders/domain/enums/work_order_status.dart';
import '../localization/locale_cubit.dart';
import 'role_nav_config.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/desktop_topbar.dart';
import 'widgets/animated_bottom_nav_bar.dart';

/// Root navigation shell that switches between mobile bottom-nav
/// and desktop sidebar layouts based on screen width.
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
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final currentUser = authState is Authenticated
                ? authState.user
                : null;
            final currentRole =
                currentUser?.role ?? UserRole.maintenanceSupervisor;

            // Reset tab index if role changed to avoid index out of range
            if (_lastRole != currentRole) {
              _lastRole = currentRole;
              _currentIndex = 0;
            }

            return BlocBuilder<WorkOrderCubit, WorkOrderState>(
              builder: (context, woState) {
                final assignedCount = _countAssignedOrders(
                  woState,
                  currentUser,
                );
                final config = RoleNavConfig.build(
                  context,
                  currentRole,
                  assignedCount,
                );

                final safeIndex = _currentIndex < config.screens.length
                    ? _currentIndex
                    : 0;

                final isWideScreen = MediaQuery.of(context).size.width >= 850;

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
      },
    );
  }

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

  Widget _buildDesktopLayout(
    BuildContext context,
    RoleNavConfig config,
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

  Widget _buildMobileLayout(RoleNavConfig config, int safeIndex) {
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: config.screens),
      bottomNavigationBar: AnimatedBottomNavBar(
        tabs: config.tabs,
        selectedIndex: safeIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
