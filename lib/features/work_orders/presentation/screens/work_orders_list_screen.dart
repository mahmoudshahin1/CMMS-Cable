import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/enums/priority.dart';
import 'work_order_detail_screen.dart';
import 'create_repair_request_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../auth/presentation/widgets/role_guard.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/data/mock_users.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/presentation/cubit/machine_state.dart';

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
                    builder: (context) => const CreateRepairRequestScreen(),
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
                    builder: (context) => const SettingsScreen(),
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
          final userDept = currentUser?.department;
          final hasDeptScope = userDept != null && !isPlantManager;

          // Retrieve machines to map machineId to department
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

          // Strict Scoping:
          // 1. If technician or assigned-only filter active: ONLY orders assigned to this user
          // 2. If department user: orders for machines in their department
          // 3. If plant manager / supervisor: all orders
          final List<WorkOrderModel> scopedOrders = (isTech || _onlyMyTasks)
              ? allOrders.where((wo) => wo.assignedToTechnicianId == currentUser?.id).toList()
              : (hasDeptScope
                  ? allOrders.where((wo) => machineMap[wo.machineId]?.department == userDept).toList()
                  : allOrders);

          final myOrders = scopedOrders;
          final pendingAssignments = isTech
              ? myOrders.where((wo) => wo.status == WorkOrderStatus.assigned).toList()
              : <WorkOrderModel>[];

          List<WorkOrderModel> filteredList = [];
          if (state is WorkOrderLoaded) {
            filteredList = List<WorkOrderModel>.from(scopedOrders);

            if (_statusFilter != null) {
              filteredList = filteredList
                  .where((wo) => wo.status == _statusFilter)
                  .toList();
            }

            // Sort newest first
            filteredList
                .sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<WorkOrderCubit>().loadWorkOrders(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Department Scope Indicator Banner (For department users)
                if (hasDeptScope)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.cyberCyan.withValues(alpha: 0.1)
                            : AppColors.energyaLightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.isDarkMode
                              ? AppColors.cyberCyan.withValues(alpha: 0.4)
                              : AppColors.energyaBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaPrimaryBlue,
                              size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.trArgs('dept_scope_label', {'dept': userDept.displayName}),
                                  style: TextStyle(
                                    color: context.isDarkMode ? Colors.white : AppColors.energyaTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  context.tr('dept_scope_sub'),
                                  style: TextStyle(
                                    color: context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.cyberCyan.withValues(alpha: 0.25)
                                  : AppColors.energyaPrimaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.trArgs('ticket_count', {'count': scopedOrders.length.toString()}),
                              style: TextStyle(
                                color: context.isDarkMode ? Colors.white : AppColors.energyaPrimaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Plant Manager Global Scope Banner
                if (isPlantManager)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.runningEmerald.withValues(alpha: 0.1)
                            : AppColors.energyaLightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.isDarkMode
                              ? AppColors.runningEmerald.withValues(alpha: 0.4)
                              : AppColors.energyaBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: AppColors.runningEmerald, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('plant_mgr_scope'),
                              style: TextStyle(
                                color: context.isDarkMode ? Colors.white : AppColors.energyaTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              context.trArgs('ticket_count', {'count': allOrders.length.toString()}),
                              style: const TextStyle(
                                color: AppColors.runningEmerald,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Technician Scope Banner (Strictly distributed tasks)
                if (isTech)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? (currentUser?.speciality == 'Electrical' ? AppColors.electricBlue : AppColors.cyberCyan)
                                .withValues(alpha: 0.1)
                            : AppColors.energyaLightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.isDarkMode
                              ? (currentUser?.speciality == 'Electrical' ? AppColors.electricBlue : AppColors.cyberCyan)
                                  .withValues(alpha: 0.4)
                              : AppColors.energyaBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentUser?.speciality == 'Electrical' ? Icons.bolt_rounded : Icons.build_circle_rounded,
                            color: currentUser?.speciality == 'Electrical' ? context.brandPrimary : context.brandAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.speciality == 'Electrical' ? context.tr('tech_scope_electrical') : context.tr('tech_scope_mechanical'),
                                  style: TextStyle(
                                    color: context.isDarkMode ? Colors.white : AppColors.energyaTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  context.tr('tech_scope_sub'),
                                  style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? (currentUser?.speciality == 'Electrical' ? AppColors.electricBlue : AppColors.cyberCyan)
                                      .withValues(alpha: 0.25)
                                  : AppColors.energyaPrimaryBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.trArgs('ticket_count', {'count': scopedOrders.length.toString()}),
                              style: TextStyle(
                                color: context.isDarkMode ? Colors.white : AppColors.energyaPrimaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Urgent Alert Banner for Technician if newly assigned
                if (isTech && pendingAssignments.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.energyaAccentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.energyaAccentOrange.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.energyaAccentOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.trArgs('pending_assignments_msg', {'count': pendingAssignments.length.toString()}),
                              style: TextStyle(
                                color: context.isDarkMode ? Colors.white : AppColors.energyaTextPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Filter Tabs / Chips Bar
                SliverToBoxAdapter(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip(context, context.tr('filter_all_label'), null),
                        _buildFilterChip(
                            context, context.tr('filter_pending_label'), WorkOrderStatus.open),
                        _buildFilterChip(
                            context, context.tr('filter_assigned_label'), WorkOrderStatus.assigned),
                        _buildFilterChip(context, context.tr('filter_in_progress_label'),
                            WorkOrderStatus.inProgress),
                        _buildFilterChip(context, context.tr('filter_completed_label'),
                            WorkOrderStatus.completed),
                        _buildFilterChip(context, context.tr('filter_verified_label'),
                            WorkOrderStatus.verified),
                        _buildFilterChip(
                            context, context.tr('filter_closed_label'), WorkOrderStatus.verifiedClosed),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Divider(color: context.borderColor, height: 1),
                ),

                // Work Orders List
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
                            color: AppColors.downMaintenanceRed),
                      ),
                    ),
                  )
                else if (state is WorkOrderLoaded) ...[
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.build_circle_outlined,
                                  size: 64, color: context.borderColor),
                              const SizedBox(height: 12),
                              Text(
                                isTech
                                    ? context.tr('no_wo_tech')
                                    : (hasDeptScope
                                        ? context.trArgs('no_wo_dept', {'dept': userDept.displayName})
                                        : context.tr('no_work_orders')),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTech
                                    ? context.tr('no_wo_tech_sub')
                                    : context.tr('no_work_orders_sub'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.textMutedColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                          top: 12, left: 16, right: 16, bottom: 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final wo = filteredList[index];
                            return _buildWorkOrderCard(
                                context, wo, machineMap[wo.machineId]);
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

  Widget _buildFilterChip(
      BuildContext context, String label, WorkOrderStatus? status) {
    final isSelected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: context.isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue,
        backgroundColor: context.cardBg,
        side: BorderSide(
          color: isSelected
              ? (context.isDarkMode ? AppColors.cyberCyan : AppColors.energyaPrimaryBlue)
              : context.borderColor,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),

        onSelected: (_) {
          setState(() {
            _statusFilter = status;
          });
        },
      ),
    );
  }

  Widget _buildWorkOrderCard(
      BuildContext context, WorkOrderModel wo, MachineModel? machine) {
    Color priorityColor = AppColors.priorityMedium;
    switch (wo.priority) {
      case Priority.low:
        priorityColor = AppColors.priorityLow;
        break;
      case Priority.medium:
        priorityColor = AppColors.priorityMedium;
        break;
      case Priority.high:
        priorityColor = AppColors.priorityHigh;
        break;
      case Priority.critical:
        priorityColor = AppColors.priorityCritical;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: priorityColor.withValues(
              alpha: context.isDarkMode ? 0.3 : 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkOrderDetailScreen(workOrder: wo),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.build_rounded, color: priorityColor, size: 20),
        ),
        title: Text(
          wo.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${machine != null ? '${machine.name} (${machine.code})' : 'Machine: ${wo.machineId}'} • ${wo.type.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.textMutedColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (machine != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cyberCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.cyberCyan.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      machine.department.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cyberCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.darkNavy
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    wo.status.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cyberCyan,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    wo.priority.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (wo.assignedToTechnicianId != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.subduedViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.subduedViolet.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.handyman_rounded,
                            size: 10, color: AppColors.subduedViolet),
                        const SizedBox(width: 3),
                        Text(
                          MockUsers.findById(wo.assignedToTechnicianId!).name.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.subduedViolet,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: context.textMutedColor),
      ),
    );
  }
}
