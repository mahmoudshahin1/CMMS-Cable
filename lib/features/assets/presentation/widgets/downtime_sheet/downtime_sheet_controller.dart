import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/chronology/event_chronology.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../downtime/domain/enums/downtime_category.dart';
import '../../../../downtime/domain/models/downtime_log_model.dart';
import '../../../../downtime/presentation/cubit/downtime_cubit.dart';
import '../../../../work_orders/domain/enums/priority.dart';
import '../../../../work_orders/domain/enums/work_order_status.dart';
import '../../../../work_orders/domain/enums/work_order_type.dart';
import '../../../../work_orders/domain/models/work_order_model.dart';
import '../../../../work_orders/presentation/cubit/work_order_cubit.dart';
import '../../../../work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../../domain/enums/department_type.dart';
import '../../../domain/enums/machine_status.dart';
import '../../../domain/models/machine_model.dart';
import '../../cubit/machine_cubit.dart';

/// Controller handling async submission, work order creation, and navigation for downtime logging.
class DowntimeSheetController {
  static Future<void> submitDowntime({
    required BuildContext context,
    required MachineModel machine,
    required DowntimeCategory category,
    required String reasonText,
    required bool isMaintenanceRequested,
  }) async {
    final reason =
        reasonText.trim().isEmpty ? category.displayName : reasonText.trim();

    final chrono = EventChronology.now();
    final newLog = DowntimeLogModel(
      id: const Uuid().v4(),
      machineId: machine.id,
      reportedById: 'OP-104',
      startTime: chrono.recordedAtUtc,
      category: category,
      reason: reason,
      isMaintenanceRequested: isMaintenanceRequested,
      startChronology: chrono,
    );

    // Capture all context-dependent variables before any async operations
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isArabic = context.isArabic;
    final loggedSnack = context.trArgs('downtime_logged_snack', {
      'code': machine.code,
    });
    final trackOrdersBtn = context.tr('track_orders_btn');
    final desc = context.trArgs('downtime_wo_desc', {
      'name': machine.name,
      'code': machine.code,
      'dept': machine.department.localizedName(isArabic),
      'reason': reason,
    });

    final downtimeCubit = context.read<DowntimeCubit>();
    final workOrderCubit = context.read<WorkOrderCubit>();
    final machineCubit = context.read<MachineCubit>();

    // 1. Log Downtime
    await downtimeCubit.reportDowntime(newLog);

    // 2. Automatically create Work Order
    if (isMaintenanceRequested || category.isMaintenance) {
      final workOrderId = const Uuid().v4();
      final newWorkOrder = WorkOrderModel(
        id: workOrderId,
        title: '${machine.code}: $reason',
        description: desc,
        machineId: machine.id,
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.open,
        priority: Priority.high,
        createdAt: chrono.recordedAtUtc,
        chronology: chrono,
        spareParts: const [],
      );

      await workOrderCubit.createWorkOrder(newWorkOrder);
    }

    // 3. Update Machine Status
    await machineCubit.updateMachineStatus(
      machine.id,
      category.isMaintenance
          ? MachineStatus.downtimeMaintenance
          : MachineStatus.downtimeProcess,
    );

    navigator.pop();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.downMaintenanceRed,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loggedSnack,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: trackOrdersBtn,
          textColor: Colors.white,
          onPressed: () {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => const WorkOrdersListScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
