import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/swipe_action_button.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import '../widgets/interactive_work_order_action_card.dart';
import '../widgets/live_mttr_timer_card.dart';
import '../widgets/root_cause_maintenance_section.dart';
import '../widgets/spare_parts_consumption_section.dart';
import '../widgets/work_order_activity_timeline_widget.dart';
import '../widgets/work_order_priority_header_card.dart';
import '../widgets/work_order_status_timeline_bar.dart';

/// Screen detailing a specific Work Order with industrial 5-step lifecycle actions.
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
  final TextEditingController _partQtyController =
      TextEditingController(text: '1');

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  void _onCompleteRepairRequested(WorkOrderModel wo) {
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
          'Field repair completed! Order forwarded for Operator test run.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slateCard,
      ),
    );
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
        final isTech =
            context.read<AuthCubit>().hasRole([UserRole.maintenanceTech]);

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
                WorkOrderPriorityHeaderCard(workOrder: wo),
                const SizedBox(height: 20),
                WorkOrderStatusTimelineBar(currentStatus: wo.status),
                const SizedBox(height: 20),
                if (wo.status == WorkOrderStatus.inProgress) ...[
                  LiveMttrTimerCard(formattedTimer: _formattedTimer),
                  const SizedBox(height: 20),
                ],
                InteractiveWorkOrderActionCard(
                  workOrder: wo,
                  onRepairStarted: _startTimer,
                  onCompleteRepairRequested: () =>
                      _onCompleteRepairRequested(wo),
                ),
                const SizedBox(height: 20),
                SparePartsConsumptionSection(
                  workOrder: wo,
                  isCompleted: isCompleted,
                  canAddParts: isTech,
                  partNameController: _partNameController,
                  partQtyController: _partQtyController,
                  onAddSparePart: _addSparePart,
                ),
                const SizedBox(height: 20),
                RootCauseMaintenanceSection(
                  rootCauseController: _rootCauseController,
                  actionsTakenController: _actionsTakenController,
                  isEnabled: !isCompleted &&
                      wo.status == WorkOrderStatus.inProgress &&
                      isTech,
                ),
                const SizedBox(height: 24),
                WorkOrderActivityTimelineWidget(
                  activityLogs: wo.activityLogs,
                  workOrder: wo,
                ),
                const SizedBox(height: 24),
                if (!isCompleted &&
                    wo.status == WorkOrderStatus.inProgress &&
                    isTech) ...[
                  SwipeActionButton(
                    label: 'Swipe to Complete Field Repair',
                    backgroundColor: AppColors.runningEmerald,
                    icon: Icons.check_circle_rounded,
                    onSwipeCompleted: () {
                      final currentUser =
                          context.read<AuthCubit>().currentUser;
                      context.read<WorkOrderCubit>().completeWorkOrder(
                            wo.id,
                            rootCause:
                                _rootCauseController.text.trim().isNotEmpty
                                    ? _rootCauseController.text.trim()
                                    : 'Maintenance fix completed',
                            actionsTaken:
                                _actionsTakenController.text.trim().isNotEmpty
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
}
