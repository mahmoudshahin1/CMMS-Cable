import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/machine_status.dart';
import '../../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../../auth/domain/models/user_model.dart';
import '../../../domain/models/work_order_model.dart';
import '../../../domain/enums/work_order_type.dart';
import '../../../domain/enums/work_order_status.dart';
import '../../cubit/work_order_cubit.dart';
import '../../cubit/work_order_state.dart';

/// Handles async operations and user feedback for the 5-Step Handshake.
class HandshakeActionController {
  final BuildContext context;
  final WorkOrderModel workOrder;

  const HandshakeActionController({
    required this.context,
    required this.workOrder,
  });

  Future<void> startRepair(UserModel user, {VoidCallback? onStarted}) async {
    final messenger = ScaffoldMessenger.of(context);
    final workOrderCubit = context.read<WorkOrderCubit>();
    final machineCubit = context.read<MachineCubit>();
    final isDark = context.isDarkMode;

    await workOrderCubit.startRepair(workOrder.id, caller: user);
    await machineCubit.updateMachineStatus(
      workOrder.machineId,
      MachineStatus.underRepair,
    );
    onStarted?.call();

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Repair started! Machine set to UNDER REPAIR and MTTR timer activated.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.slateCard : AppColors.energyaDeepNavy,
      ),
    );
  }

  Future<void> completeRepair(
    UserModel user, {
    VoidCallback? onCompleteRequested,
  }) async {
    if (onCompleteRequested != null) {
      onCompleteRequested();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final workOrderCubit = context.read<WorkOrderCubit>();
    final isDark = context.isDarkMode;

    await workOrderCubit.completeWorkOrder(
      workOrder.id,
      rootCause: 'Maintenance fix completed',
      actionsTaken: 'Field repair completed',
      caller: user,
    );

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Repair completed! Waiting for Operator field test run.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.slateCard : AppColors.energyaDeepNavy,
      ),
    );
  }

  Future<void> confirmTestRun(UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    final workOrderCubit = context.read<WorkOrderCubit>();
    final machineCubit = context.read<MachineCubit>();
    final isDark = context.isDarkMode;

    await workOrderCubit.confirmTestRun(workOrder.id, caller: user);

    final currentState = workOrderCubit.state;
    final allList = currentState is WorkOrderLoaded
        ? currentState.allWorkOrders
        : <WorkOrderModel>[];

    final hasOtherActiveBreakdown = allList.any(
      (w) =>
          w.machineId == workOrder.machineId &&
          w.id != workOrder.id &&
          w.type == WorkOrderType.breakdown &&
          w.status != WorkOrderStatus.verifiedClosed,
    );

    if (!hasOtherActiveBreakdown) {
      await machineCubit.updateMachineStatus(
        workOrder.machineId,
        MachineStatus.running,
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          !hasOtherActiveBreakdown
              ? 'Test run confirmed! Machine is now RUNNING. Ticket forwarded for Supervisor sign-off.'
              : 'Test run confirmed! Machine remains under maintenance due to concurrent active ticket.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.slateCard : AppColors.energyaDeepNavy,
      ),
    );
  }

  Future<void> approveAndClose(UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    final workOrderCubit = context.read<WorkOrderCubit>();
    final isDark = context.isDarkMode;

    await workOrderCubit.approveAndClose(workOrder.id, caller: user);

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Work order approved and closed successfully. Archive updated.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.slateCard : AppColors.energyaDeepNavy,
      ),
    );
  }
}
