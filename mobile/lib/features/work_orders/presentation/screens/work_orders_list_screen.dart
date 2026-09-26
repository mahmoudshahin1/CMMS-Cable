import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/presentation/cubit/machine_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../widgets/work_order_empty_state.dart';
import '../widgets/work_order_filter_bar.dart';
import '../widgets/work_order_list_card.dart';
import '../widgets/work_order_scope_banner.dart';
import 'create_repair_request_screen.dart';

/// Screen displaying filtered, scoped industrial Work Orders.
class WorkOrdersListScreen extends StatefulWidget {
  final bool assignedOnly;

  const WorkOrdersListScreen({super.key, this.assignedOnly = false});

  @override
  State<WorkOrdersListScreen> createState() => _WorkOrdersListScreenState();
}

class _WorkOrdersListScreenState extends State<WorkOrdersListScreen> {
  WorkOrderStatus? _statusFilter;
  late bool _onlyMyTasks;

  @override
  void initState() {
    super.initState();
    _onlyMyTasks = widget.assignedOnly;
    context.read<WorkOrderCubit>().loadWorkOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(context.tr('wo_screen_title')),
        ),
        actions: [
          const PersonaIndicatorChip(compact: true),
          const SizedBox(width: 4),
          RoleGuard(
            allowedRoles: const [
              UserRole.operator,
              UserRole.maintenanceSupervisor,
            ],
            child: IconButton(
              icon: const Icon(Icons.add_task_rounded),
              tooltip: context.tr('new_breakdown_tooltip'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateRepairRequestScreen(),
                  ),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: context.tr('more_btn'),
            onSelected: (value) {
              if (value == 'refresh') {
                context.read<WorkOrderCubit>().loadWorkOrders();
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(context.tr('refresh_btn')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(context.tr('settings_title')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: BlocBuilder<WorkOrderCubit, WorkOrderState>(
        builder: (context, state) {
          final currentUser = context.watch<AuthCubit>().currentUser;
          final isTech = currentUser?.role == UserRole.maintenanceTech;
          final isPlantManager = currentUser?.role == UserRole.plantManager;
          final isOperator = currentUser?.role == UserRole.operator;
          final userDept = currentUser?.department;
          final hasDeptScope = isOperator || (userDept != null && !isPlantManager);

          // Machine map for department lookups
          final machineState = context.watch<MachineCubit>().state;
          final Map<String, MachineModel> machineMap = {};
          if (machineState is MachineLoaded) {
            for (final m in machineState.allMachines) {
              machineMap[m.id] = m;
            }
          }

          List<WorkOrderModel> allOrders = [];
          if (state is WorkOrderLoaded) {
            allOrders = state.allWorkOrders;
          }

          // Strict Scoping: Tech / Dept / Plant Wide
          final List<WorkOrderModel> scopedOrders = (isTech || _onlyMyTasks)
              ? allOrders
                  .where((wo) => wo.assignedToTechnicianId == currentUser?.id)
                  .toList()
              : (hasDeptScope && userDept != null
                  ? allOrders
                      .where((wo) =>
                          machineMap[wo.machineId]?.department == userDept)
                      .toList()
                  : (isOperator ? <WorkOrderModel>[] : allOrders));

          final pendingAssignments = isTech
              ? scopedOrders
                  .where((wo) => wo.status == WorkOrderStatus.assigned)
                  .toList()
              : <WorkOrderModel>[];

          List<WorkOrderModel> filteredList = [];
          if (state is WorkOrderLoaded) {
            filteredList = List<WorkOrderModel>.from(scopedOrders);

            if (_statusFilter != null) {
              filteredList =
                  filteredList.where((wo) => wo.status == _statusFilter).toList();
            }

            filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<WorkOrderCubit>().loadWorkOrders(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: WorkOrderScopeBanner(
                    currentUser: currentUser,
                    scopedCount: scopedOrders.length,
                    allCount: allOrders.length,
                    pendingAssignmentsCount: pendingAssignments.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: WorkOrderFilterBar(
                    selectedStatus: _statusFilter,
                    onStatusChanged: (status) =>
                        setState(() => _statusFilter = status),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Divider(color: context.borderColor, height: 1),
                ),
                if (state is WorkOrderLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is WorkOrderError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(
                          color: AppColors.downMaintenanceRed,
                        ),
                      ),
                    ),
                  )
                else if (state is WorkOrderLoaded) ...[
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: WorkOrderEmptyState(
                        isTech: isTech,
                        hasDeptScope: hasDeptScope,
                        departmentName: userDept?.displayName,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 16,
                        right: 16,
                        bottom: 32,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final wo = filteredList[index];
                            return WorkOrderListCard(
                              workOrder: wo,
                              machine: machineMap[wo.machineId],
                            );
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ] else
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Initialize Work Orders')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
