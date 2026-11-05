import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/outbox/outbox_command.dart';
import '../../../../core/sync/outbox/outbox_local_data_source.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../cubit/work_order_state.dart';
import 'open_form_chip.dart';

/// Global persistent status strip displaying all active/open forms with live sync dot indicator.
class GlobalOpenFormsStrip extends StatefulWidget {
  final OutboxLocalDataSource? outboxLocal;
  final OutboxSyncEngine? syncEngine;

  const GlobalOpenFormsStrip({
    super.key,
    this.outboxLocal,
    this.syncEngine,
  });

  @override
  State<GlobalOpenFormsStrip> createState() => _GlobalOpenFormsStripState();
}

class _GlobalOpenFormsStripState extends State<GlobalOpenFormsStrip> {
  bool _isExpanded = true;
  Map<String, FormSyncStatus> _formSyncMap = {};
  StreamSubscription<int>? _outboxSub;

  OutboxLocalDataSource? get _outbox =>
      widget.outboxLocal ??
      (getIt.isRegistered<OutboxLocalDataSource>()
          ? getIt<OutboxLocalDataSource>()
          : null);

  OutboxSyncEngine? get _syncEngine =>
      widget.syncEngine ??
      (getIt.isRegistered<OutboxSyncEngine>()
          ? getIt<OutboxSyncEngine>()
          : null);

  @override
  void initState() {
    super.initState();
    _outboxSub = _syncEngine?.pendingCountStream.listen((_) {
      if (mounted) _refreshSyncStatuses();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSyncStatuses());
  }

  @override
  void dispose() {
    _outboxSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshSyncStatuses() async {
    final outbox = _outbox;
    if (outbox == null) return;

    final state = context.read<WorkOrderCubit>().state;
    if (state is! WorkOrderLoaded) return;

    final openOrders = state.allWorkOrders.where(_isActiveStatus).toList();
    final Map<String, FormSyncStatus> nextMap = {};

    for (final wo in openOrders) {
      try {
        final commands = await outbox.getCommandsForAggregate(wo.id);
        if (commands.isEmpty) {
          nextMap[wo.id] = FormSyncStatus.syncedGreen;
        } else if (commands.any((c) =>
            c.status == OutboxCommandStatus.deadLetter ||
            c.status == OutboxCommandStatus.failed ||
            c.status == OutboxCommandStatus.failedConflict ||
            c.status == OutboxCommandStatus.failedRejected)) {
          nextMap[wo.id] = FormSyncStatus.errorRed;
        } else if (commands.any((c) => c.status == OutboxCommandStatus.inFlight)) {
          nextMap[wo.id] = FormSyncStatus.inFlightBlue;
        } else {
          nextMap[wo.id] = FormSyncStatus.dirtyAmber;
        }
      } catch (_) {
        nextMap[wo.id] = FormSyncStatus.syncedGreen;
      }
    }

    if (mounted) setState(() => _formSyncMap = nextMap);
  }

  bool _isActiveStatus(WorkOrderModel wo) {
    return wo.status == WorkOrderStatus.open ||
        wo.status == WorkOrderStatus.assigned ||
        wo.status == WorkOrderStatus.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkOrderCubit, WorkOrderState>(
      listener: (context, state) {
        if (state is WorkOrderLoaded) _refreshSyncStatuses();
      },
      builder: (context, state) {
        if (state is! WorkOrderLoaded) return const SizedBox.shrink();

        final activeOrders =
            state.allWorkOrders.where(_isActiveStatus).toList();
        if (activeOrders.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.2 : 0.04,
                ),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 15,
                    color: context.brandPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OPEN FORMS',
                    style: TextStyle(
                      color: context.isDarkMode
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: context.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeOrders.length}',
                      style: TextStyle(
                        color: context.brandPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: context.textMutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: activeOrders.length,
                    itemBuilder: (context, index) {
                      final wo = activeOrders[index];
                      final status =
                          _formSyncMap[wo.id] ?? FormSyncStatus.syncedGreen;
                      return OpenFormChip(workOrder: wo, syncStatus: status);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

