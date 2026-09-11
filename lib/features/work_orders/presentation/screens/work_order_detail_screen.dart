import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/enums/priority.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/swipe_action_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../widgets/interactive_work_order_action_card.dart';
import '../widgets/work_order_activity_timeline_widget.dart';

class WorkOrderDetailScreen extends StatefulWidget {
  final WorkOrderModel workOrder;

  const WorkOrderDetailScreen({super.key, required this.workOrder});

  @override
  State<WorkOrderDetailScreen> createState() => _WorkOrderDetailScreenState();
}

class _WorkOrderDetailScreenState extends State<WorkOrderDetailScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  final TextEditingController _rootCauseController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _partQtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _rootCauseController.text = widget.workOrder.rootCause ?? '';
    _actionsTakenController.text = widget.workOrder.actionsTaken ?? '';

    if (widget.workOrder.status == WorkOrderStatus.inProgress &&
        widget.workOrder.startedAt != null) {
      _elapsedSeconds =
          DateTime.now().difference(widget.workOrder.startedAt!).inSeconds;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rootCauseController.dispose();
    _actionsTakenController.dispose();
    _partNameController.dispose();
    _partQtyController.dispose();
    super.dispose();
  }

  String get _formattedTimer {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _priorityColor {
    switch (widget.workOrder.priority) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.critical:
        return AppColors.priorityCritical;
    }
  }

  void _addSparePart() {
    final name = _partNameController.text.trim();
    final qty = int.tryParse(_partQtyController.text.trim()) ?? 1;

    if (name.isNotEmpty) {
      final part = SparePartModel(
        id: const Uuid().v4(),
        partNumber: 'PN-${const Uuid().v4().substring(0, 5).toUpperCase()}',
        name: name,
        quantityUsed: qty,
        unitCost: 45.0,
      );

      final currentUser = context.read<AuthCubit>().currentUser;
      context.read<WorkOrderCubit>().addSparePart(
            widget.workOrder.id,
            part,
            caller: currentUser,
          );
      _partNameController.clear();
      _partQtyController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkOrderCubit, WorkOrderState>(
      builder: (context, state) {
        WorkOrderModel wo = widget.workOrder;
        if (state is WorkOrderLoaded) {
          wo = state.allWorkOrders.firstWhere(
            (w) => w.id == widget.workOrder.id,
            orElse: () => widget.workOrder,
          );
        }
        final isCompleted = wo.status == WorkOrderStatus.completed ||
            wo.status == WorkOrderStatus.verified ||
            wo.status == WorkOrderStatus.verifiedClosed;

        return Scaffold(
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('WO: ${wo.title}'),
            ),
            actions: const [
              PersonaIndicatorChip(compact: true),
              SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Priority & Title Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.isDarkMode
                      ? _priorityColor.withValues(alpha: 0.6)
                      : context.borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _priorityColor.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRIORITY: ${wo.priority.displayName.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        wo.type.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.brandPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    wo.title,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Machine ID: ${wo.machineId}',
                    style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wo.description,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Work Order Status Stepper
            Text(
              'REPAIR STATUS TIMELINE',
              style: TextStyle(
                color: context.isDarkMode
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusTimeline(wo.status),
            const SizedBox(height: 20),

            // Live MTTR Repair Timer
            if (wo.status == WorkOrderStatus.inProgress) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? AppColors.darkNavy : AppColors.energyaWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDarkMode ? AppColors.electricBlue : AppColors.energyaPrimaryBlue,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE ELAPSED REPAIR TIME (MTTR)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textMutedColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Technician Working...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.brandAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formattedTimer,
                        style: TextStyle(
                          color: context.brandPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],


            // 5-Step Handshake Interactive Dynamic Action Card
            InteractiveWorkOrderActionCard(
              workOrder: wo,
              onRepairStarted: _startTimer,
              onCompleteRepairRequested: () {
                final currentUser = context.read<AuthCubit>().currentUser;
                context.read<WorkOrderCubit>().completeWorkOrder(
                      wo.id,
                      rootCause: _rootCauseController.text.trim().isNotEmpty
                          ? _rootCauseController.text.trim()
                          : 'Maintenance fix completed',
                      actionsTaken: _actionsTakenController.text.trim().isNotEmpty
                          ? _actionsTakenController.text.trim()
                          : 'Machine components repaired & restored',
                      caller: currentUser,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Field repair completed! Order forwarded for Operator test run.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.slateCard,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Spare Parts Counter & Chips
            Text(
              'SPARE PARTS CONSUMED',
              style: TextStyle(
                color: context.isDarkMode
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            if (!isCompleted &&
                wo.status == WorkOrderStatus.inProgress &&
                context.read<AuthCubit>().hasRole([UserRole.maintenanceTech])) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _partNameController,
                      style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Part name (e.g. O-Ring)',
                        hintStyle: TextStyle(color: context.textMutedColor),
                        filled: true,
                        fillColor: context.cardBg,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.brandPrimary),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _partQtyController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Qty',
                        hintStyle: TextStyle(color: context.textMutedColor),
                        filled: true,
                        fillColor: context.cardBg,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.brandPrimary),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _addSparePart,
                    icon: Icon(Icons.add_circle,
                        color: context.brandPrimary, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: wo.spareParts.map((part) {
                return Chip(
                  avatar: Icon(Icons.settings_suggest,
                      size: 14, color: context.brandPrimary),
                  label: Text(
                    '${part.name} (x${part.quantityUsed})',
                    style: TextStyle(color: context.textPrimaryColor, fontSize: 12),
                  ),
                  backgroundColor: context.isDarkMode
                      ? AppColors.slateCard
                      : AppColors.energyaLightSurface,
                  side: BorderSide(color: context.borderColor),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Root Cause & Action Taken
            Text(
              'ROOT CAUSE & MAINTENANCE ACTIONS',
              style: TextStyle(
                color: context.isDarkMode
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Root Cause Breakdown Analysis',
              style: TextStyle(
                color: context.brandPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _rootCauseController,
              enabled: !isCompleted &&
                  wo.status == WorkOrderStatus.inProgress &&
                  context.read<AuthCubit>().hasRole([UserRole.maintenanceTech]),
              style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                hintText: 'Enter root cause breakdown analysis...',
                hintStyle: TextStyle(color: context.textMutedColor),
                filled: true,
                fillColor: context.cardBg,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.brandPrimary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Actions Taken & Repair Steps',
              style: TextStyle(
                color: context.brandPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _actionsTakenController,
              enabled: !isCompleted &&
                  wo.status == WorkOrderStatus.inProgress &&
                  context.read<AuthCubit>().hasRole([UserRole.maintenanceTech]),
              style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                hintText: 'Enter repair steps performed...',
                hintStyle: TextStyle(color: context.textMutedColor),
                filled: true,
                fillColor: context.cardBg,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.brandPrimary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Certified Tamper-Proof Audit & Activity Timeline
            WorkOrderActivityTimelineWidget(
              activityLogs: wo.activityLogs,
              workOrder: wo,
            ),
            const SizedBox(height: 24),

            if (!isCompleted &&
                wo.status == WorkOrderStatus.inProgress &&
                context.read<AuthCubit>().hasRole([UserRole.maintenanceTech])) ...[
              SwipeActionButton(
                label: 'Swipe to Complete Field Repair',
                backgroundColor: AppColors.runningEmerald,
                icon: Icons.check_circle_rounded,
                onSwipeCompleted: () {
                  final currentUser = context.read<AuthCubit>().currentUser;
                  context.read<WorkOrderCubit>().completeWorkOrder(
                        wo.id,
                        rootCause: _rootCauseController.text.trim().isNotEmpty
                            ? _rootCauseController.text.trim()
                            : 'Maintenance fix completed',
                        actionsTaken: _actionsTakenController.text.trim().isNotEmpty
                            ? _actionsTakenController.text.trim()
                            : 'Field repair completed',
                        caller: currentUser,
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildStatusTimeline(WorkOrderStatus currentStatus) {
    final steps = [
      WorkOrderStatus.open,
      WorkOrderStatus.assigned,
      WorkOrderStatus.inProgress,
      WorkOrderStatus.completed,
      WorkOrderStatus.verified,
      WorkOrderStatus.verifiedClosed,
    ];

    return Row(
      children: steps.map((status) {
        final isPassed = currentStatus.index >= status.index;
        final stepLabel = status == WorkOrderStatus.open
            ? 'Report'
            : status == WorkOrderStatus.assigned
                ? 'Triage'
                : status == WorkOrderStatus.inProgress
                    ? 'Repair'
                    : status == WorkOrderStatus.completed
                        ? 'Fixed'
                        : status == WorkOrderStatus.verified
                            ? 'Test Run'
                            : 'Closed';

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isPassed
                      ? context.brandPrimary
                      : (context.isDarkMode ? AppColors.slateBorder : AppColors.energyaBorder),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.check : Icons.circle,
                  size: 13,
                  color: isPassed
                      ? Colors.white
                      : (context.isDarkMode
                          ? AppColors.textMuted
                          : AppColors.lightTextMuted),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  stepLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? (isPassed ? Colors.white : AppColors.textMuted)
                        : (isPassed
                            ? AppColors.energyaTextPrimary
                            : AppColors.energyaTextMuted),
                    fontSize: 9.5,
                    fontWeight: isPassed ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

