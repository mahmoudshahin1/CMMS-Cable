import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/database/hive_service.dart';
import 'core/di/service_locator.dart';
import 'core/localization/locale_cubit.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'features/assets/presentation/cubit/machine_cubit.dart';
import 'features/downtime/presentation/cubit/downtime_cubit.dart';
import 'features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'features/analytics/presentation/cubit/analytics_cubit.dart';
import 'features/assets/presentation/screens/plant_overview_screen.dart';
import 'features/work_orders/presentation/screens/work_orders_list_screen.dart';
import 'features/analytics/presentation/screens/plant_analytics_screen.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/domain/enums/user_role.dart';
import 'features/work_orders/presentation/cubit/work_order_state.dart';
import 'features/work_orders/domain/enums/work_order_status.dart';
import 'features/work_orders/presentation/screens/technician_notifications_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/energya_logo.dart';
import 'features/auth/presentation/screens/settings_screen.dart';
import 'features/auth/presentation/widgets/switch_persona_bottom_sheet.dart';
import 'features/work_orders/presentation/screens/create_repair_request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Storage & Register Adapters
  await HiveService.init();

  // Initialize Dependency Injection
  await setupServiceLocator();

  runApp(const CableCmmsApp());
}

class CableCmmsApp extends StatelessWidget {
  const CableCmmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<LocaleCubit>(create: (context) => LocaleCubit()),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
        BlocProvider<MachineCubit>(
          create: (context) => getIt<MachineCubit>()..loadMachines(),
        ),
        BlocProvider<DowntimeCubit>(
          create: (context) => getIt<DowntimeCubit>()..loadDowntimeLogs(),
        ),
        BlocProvider<WorkOrderCubit>(
          create: (context) => getIt<WorkOrderCubit>()..loadWorkOrders(),
        ),
        BlocProvider<AnalyticsCubit>(
          create: (context) => AnalyticsCubit(
            machineCubit: context.read<MachineCubit>(),
            downtimeCubit: context.read<DowntimeCubit>(),
            workOrderCubit: context.read<WorkOrderCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                title: 'Cable Manufacturing CMMS',
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: AppTheme.getLightTheme(
                  locale: locale,
                  primaryColor: themeState.primaryColor,
                  secondaryColor: themeState.secondaryColor,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  locale: locale,
                  primaryColor: themeState.primaryColor,
                  secondaryColor: themeState.secondaryColor,
                ),
                themeMode: themeState.themeMode,
                home: const MainNavigationShell(),
              );
            },
          );
        },
      ),
    );
  }
}

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
        final currentUser = authState is Authenticated ? authState.user : null;
        final currentRole = currentUser?.role ?? UserRole.maintenanceSupervisor;

        // Reset tab index if role changed to avoid index out of range
        if (_lastRole != currentRole) {
          _lastRole = currentRole;
          _currentIndex = 0;
        }

        return BlocBuilder<WorkOrderCubit, WorkOrderState>(
          builder: (context, woState) {
            // Count pending tasks for notification badge
            int assignedCount = 0;
            if (woState is WorkOrderLoaded && currentUser != null) {
              assignedCount = woState.allWorkOrders
                  .where(
                    (wo) =>
                        wo.assignedToTechnicianId == currentUser.id &&
                        wo.status == WorkOrderStatus.assigned,
                  )
                  .length;
            }

            final List<Widget> screens;
            final List<BottomNavigationBarItem> navItems;
            final List<({IconData icon, String label})> sidebarItems;

            switch (currentRole) {
              case UserRole.maintenanceTech:
                screens = const [
                  WorkOrdersListScreen(assignedOnly: true),
                  TechnicianNotificationsScreen(),
                ];
                navItems = [
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
                ];
                sidebarItems = [
                  (
                    icon: Icons.assignment_turned_in_rounded,
                    label: context.tr('tab_my_tasks'),
                  ),
                  (
                    icon: Icons.notifications_active_rounded,
                    label: context.tr('tab_notifications'),
                  ),
                ];
                break;

              case UserRole.operator:
                screens = const [PlantOverviewScreen(), WorkOrdersListScreen()];
                navItems = [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.factory_rounded),
                    label: context.tr('tab_factory'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.build_rounded),
                    label: context.tr('tab_work_orders'),
                  ),
                ];
                sidebarItems = [
                  (
                    icon: Icons.factory_rounded,
                    label: context.tr('tab_factory'),
                  ),
                  (
                    icon: Icons.build_rounded,
                    label: context.tr('tab_work_orders'),
                  ),
                ];
                break;

              case UserRole.plantManager:
                screens = const [
                  PlantAnalyticsScreen(),
                  PlantOverviewScreen(),
                  WorkOrdersListScreen(),
                ];
                navItems = [
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
                ];
                sidebarItems = [
                  (
                    icon: Icons.insights_rounded,
                    label: context.tr('tab_executive'),
                  ),
                  (
                    icon: Icons.factory_rounded,
                    label: context.tr('tab_factory'),
                  ),
                  (
                    icon: Icons.inventory_2_rounded,
                    label: context.tr('tab_work_orders'),
                  ),
                ];
                break;

              case UserRole.maintenanceSupervisor:
              case UserRole.productionSupervisor:
                screens = const [
                  PlantOverviewScreen(),
                  WorkOrdersListScreen(),
                  PlantAnalyticsScreen(),
                ];
                navItems = [
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
                ];
                sidebarItems = [
                  (
                    icon: Icons.factory_rounded,
                    label: context.tr('tab_factory'),
                  ),
                  (
                    icon: Icons.build_rounded,
                    label: context.tr('tab_work_orders'),
                  ),
                  (
                    icon: Icons.bar_chart_rounded,
                    label: context.tr('tab_analytics'),
                  ),
                ];
                break;
            }

            final safeIndex = _currentIndex < screens.length
                ? _currentIndex
                : 0;

            final isWideScreen = MediaQuery.of(context).size.width >= 850;

            if (isWideScreen) {
              return Scaffold(
                body: Row(
                  children: [
                    // Fixed Desktop / Tablet Sidebar in Energya Deep Navy
                    Container(
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
                          // Top Sidebar Logo & Industrial Branding
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
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
                                    Flexible(
                                      child: const Text(
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
                          ),

                          const SizedBox(height: 12),

                          // Navigation Items
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: sidebarItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final item = sidebarItems[index];
                                final isSelected = safeIndex == index;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () =>
                                      setState(() => _currentIndex = index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.energyaAccentOrange
                                                .withValues(alpha: 0.18)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors
                                                  .energyaAccentOrange
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
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color:
                                                  AppColors.energyaAccentOrange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // User Profile & Fast Switcher in Sidebar Footer
                          Container(
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
                                  onTap: () =>
                                      SwitchPersonaBottomSheet.show(context),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: currentRole.roleColor
                                            .withValues(alpha: 0.25),
                                        child: Icon(
                                          currentRole.icon,
                                          color: currentRole.roleColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentUser?.name ??
                                                  context.tr('shift_manager'),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.language_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      tooltip: context.tr('lang_toggle'),
                                      onPressed: () => context
                                          .read<LocaleCubit>()
                                          .toggleLanguage(),
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
                                      onPressed: () => context
                                          .read<ThemeCubit>()
                                          .toggleTheme(),
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
                                            builder: (context) =>
                                                const SettingsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content Area
                    Expanded(
                      child: Column(
                        children: [
                          // Top App Bar for Desktop
                          Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.darkNavy
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: context.borderColor),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Breadcrumbs
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Energya Cables  /  ',
                                        style: TextStyle(
                                          color: context.textMutedColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          sidebarItems[safeIndex].label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: context.textPrimaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateRepairRequestScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.energyaAccentOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_task_rounded,
                                    size: 16,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      context.tr('repair_request_btn'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: IndexedStack(
                              index: safeIndex,
                              children: screens,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Compact Mobile Navigation (Preserves 100% existing mobile flows)
            return Scaffold(
              body: IndexedStack(index: safeIndex, children: screens),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: safeIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: navItems,
              ),
            );
          },
        );
      },
    );
  }
}
