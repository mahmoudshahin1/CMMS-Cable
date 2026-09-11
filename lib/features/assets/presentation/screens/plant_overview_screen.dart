import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/machine_cubit.dart';
import '../cubit/machine_state.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/enums/department_type.dart';
import '../widgets/downtime_report_sheet.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../../work_orders/presentation/screens/work_orders_list_screen.dart';
import 'qr_machine_scanner_screen.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/kpi_metric_card.dart';
import '../../../../core/widgets/department_chip_bar.dart';
import '../../../../core/widgets/machine_card.dart';
import '../../../../core/widgets/energya_logo.dart';
import '../../../../core/utils/responsive_helper.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../auth/presentation/screens/settings_screen.dart';

class PlantOverviewScreen extends StatelessWidget {
  const PlantOverviewScreen({super.key});

  void _showDowntimeSheet(BuildContext context, MachineModel machine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DowntimeReportSheet(machine: machine),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context.read<MachineCubit>().loadMachines(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      // 1. Logo
                      const EnergyaLogo(height: 22, showContainer: true),

                      // 2. Persona Indicator
                      const PersonaIndicatorChip(compact: true),

                      // 3. Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Settings & Profile Button
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: context.tr('settings_title'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.settings_rounded,
                              color: context.textSecondaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Button to open Work Orders
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: context.tr('tab_work_orders'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WorkOrdersListScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.build_circle_rounded,
                              color: context.brandPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Compact Repair Request Button beside QR (Guarded by RBAC)
                          RoleGuard(
                            allowedRoles: const [
                              UserRole.operator,
                              UserRole.maintenanceSupervisor,
                            ],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateRepairRequestScreen(),
                                  ),
                                );
                              },
                              child: Tooltip(
                                message: context.tr('repair_request_btn'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.energyaAccentOrange
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.energyaAccentOrange
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_task_rounded,
                                    color: AppColors.energyaAccentOrange,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: context.tr('qr_scanner_title'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const QrMachineScannerScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: context.brandPrimary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Department Scope Indicator Banner
              SliverToBoxAdapter(
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final currentUser = authState is Authenticated
                        ? authState.user
                        : null;
                    final userDept = currentUser?.department;
                    final isPlantManager =
                        currentUser?.role == UserRole.plantManager;
                    final isTech =
                        currentUser?.role == UserRole.maintenanceTech;
                    final hasDeptScope =
                        userDept != null && !isPlantManager && !isTech;

                    if (isTech) {
                      final isElec = currentUser?.speciality == 'Electrical';
                      final color = isElec
                          ? context.brandPrimary
                          : context.brandAccent;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? color.withValues(alpha: 0.1)
                              : AppColors.energyaLightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.isDarkMode
                                ? color.withValues(alpha: 0.35)
                                : AppColors.energyaBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isElec
                                  ? Icons.bolt_rounded
                                  : Icons.build_circle_rounded,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr(isElec
                                    ? 'tech_banner_elec'
                                    : 'tech_banner_mech'),
                                style: TextStyle(
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : AppColors.energyaTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              currentUser?.email ?? '',
                              style: TextStyle(color: color, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!hasDeptScope) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.cyberCyan.withValues(alpha: 0.1)
                            : AppColors.energyaLightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.isDarkMode
                              ? AppColors.cyberCyan.withValues(alpha: 0.35)
                              : AppColors.energyaBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: context.isDarkMode
                                ? AppColors.cyberCyan
                                : AppColors.energyaPrimaryBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('dept_machines_scope', {
                                'dept': userDept.localizedName(context.isArabic),
                              }),
                              style: TextStyle(
                                color: context.isDarkMode
                                    ? Colors.white
                                    : AppColors.energyaTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            currentUser?.email ?? '',
                            style: TextStyle(
                              color: context.isDarkMode
                                  ? AppColors.cyberCyan
                                  : AppColors.energyaPrimaryBlue,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Factory KPI Bar
              SliverToBoxAdapter(
                child: BlocBuilder<MachineCubit, MachineState>(
                  builder: (context, state) {
                    final currentUser = context.watch<AuthCubit>().currentUser;
                    final userDept = currentUser?.department;
                    final isPlantManager =
                        currentUser?.role == UserRole.plantManager;
                    final hasDeptScope = userDept != null && !isPlantManager;

                    int total = 0;
                    int running = 0;
                    int downtimes = 0;

                    if (state is MachineLoaded) {
                      final scopedMachines = hasDeptScope
                          ? state.allMachines
                              .where((m) => m.department == userDept)
                              .toList()
                          : state.allMachines;

                      total = scopedMachines.length;
                      running = scopedMachines
                          .where((m) => m.status == MachineStatus.running)
                          .length;
                      downtimes = scopedMachines
                          .where((m) => m.status.isDowntime)
                          .length;
                    }

                    return SizedBox(
                      height: 104,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          KpiMetricCard(
                            title: context.tr('running'),
                            value: '$running/$total',
                            subtitle:
                                '${((running / (total > 0 ? total : 1)) * 100).toStringAsFixed(0)}% Active',
                            icon: Icons.play_circle_fill_rounded,
                            accentColor: AppColors.runningEmerald,
                          ),
                          const SizedBox(width: 10),
                          KpiMetricCard(
                            title: context.tr('active_downtime'),
                            value: '$downtimes',
                            subtitle: downtimes > 0
                                ? context.tr('requires_action')
                                : context.tr('all_clear'),
                            icon: Icons.warning_amber_rounded,
                            accentColor: AppColors.downMaintenanceRed,
                          ),
                          const SizedBox(width: 10),
                          KpiMetricCard(
                            title: hasDeptScope ? 'Dept OEE' : 'Plant OEE',
                            value: '88.4%',
                            subtitle: '+2.1% vs Target',
                            icon: Icons.analytics_rounded,
                            accentColor: context.brandPrimary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Department Horizontal Filter Chips (Locked to user department if scoped)
              SliverToBoxAdapter(
                child: BlocBuilder<MachineCubit, MachineState>(
                  builder: (context, state) {
                    final currentUser = context.watch<AuthCubit>().currentUser;
                    final userDept = currentUser?.department;
                    final isPlantManager =
                        currentUser?.role == UserRole.plantManager;
                    final hasDeptScope = userDept != null && !isPlantManager;

                    final selectedDept = hasDeptScope
                        ? userDept
                        : ((state is MachineLoaded)
                            ? state.selectedDepartment
                            : null);

                    return DepartmentChipBar(
                      selectedDepartment: selectedDept,
                      availableDepartments: hasDeptScope ? [userDept] : null,
                      showAllOption: !hasDeptScope,
                      onDepartmentSelected: (dept) {
                        if (!hasDeptScope) {
                          context.read<MachineCubit>().filterByDepartment(dept);
                        }
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Machine Grid View (Strictly scoped to user department - Full page scrollable)
              BlocBuilder<MachineCubit, MachineState>(
                builder: (context, state) {
                  final currentUser = context.watch<AuthCubit>().currentUser;
                  final userDept = currentUser?.department;
                  final isPlantManager =
                      currentUser?.role == UserRole.plantManager;
                  final hasDeptScope = userDept != null && !isPlantManager;

                  if (state is MachineLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is MachineError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Error: ${state.message}')),
                    );
                  }
                  if (state is MachineLoaded) {
                    final machines = hasDeptScope
                        ? state.allMachines
                            .where((m) => m.department == userDept)
                            .toList()
                        : state.filteredMachines;

                    if (machines.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              hasDeptScope
                                  ? context.trArgs('no_dept_machines', {
                                      'dept': userDept
                                          .localizedName(context.isArabic),
                                    })
                                  : context.tr('no_machines_found'),
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = ResponsiveHelper.gridColumnCount(
                            constraints.crossAxisExtent);
                        final aspectRatio =
                            ResponsiveHelper.machineCardAspectRatio(
                                constraints.crossAxisExtent);
                        final padding = ResponsiveHelper.horizontalPadding(
                            constraints.crossAxisExtent);
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: aspectRatio,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final machine = machines[index];
                                return MachineCard(
                                  machine: machine,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreateRepairRequestScreen(
                                          initialMachine: machine,
                                        ),
                                      ),
                                    );
                                  },
                                  onReportDowntime: () {
                                    if (machine.status.isDowntime) {
                                      _showDowntimeSheet(context, machine);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateRepairRequestScreen(
                                            initialMachine: machine,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                              childCount: machines.length,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
