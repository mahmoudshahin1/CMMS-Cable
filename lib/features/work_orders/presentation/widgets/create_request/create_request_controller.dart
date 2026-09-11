import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/chronology/event_chronology.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/machine_status.dart';
import '../../../../assets/domain/models/machine_model.dart';
import '../../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../domain/enums/priority.dart';
import '../../../domain/enums/work_order_status.dart';
import '../../../domain/enums/work_order_type.dart';
import '../../../domain/models/work_order_model.dart';
import '../../cubit/work_order_cubit.dart';
import '../../screens/work_orders_list_screen.dart';

/// Handles validation, work order creation, and navigation for repair request form.
class CreateRequestController {
  static Future<bool> submitRequest({
    required BuildContext context,
    required List<MachineModel> allMachines,
    required String? selectedMachineId,
    required GlobalKey<FormState> formKey,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required WorkOrderType selectedType,
    required Priority selectedPriority,
  }) async {
    if (allMachines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.downMaintenanceRed,
          content: Text(context.tr('no_machines_registered')),
        ),
      );
      return false;
    }

    final machineId = selectedMachineId ?? allMachines.first.id;
    final selectedMachine = allMachines.firstWhere(
      (m) => m.id == machineId,
      orElse: () => allMachines.first,
    );

    if (formKey.currentState?.validate() ?? false) {
      final chrono = EventChronology.now();
      final workOrderId = const Uuid().v4();
      final newWorkOrder = WorkOrderModel(
        id: workOrderId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? context
                .trArgs('wo_request_desc', {'code': selectedMachine.code})
            : descriptionController.text.trim(),
        machineId: selectedMachine.id,
        type: selectedType,
        status: WorkOrderStatus.open,
        priority: selectedPriority,
        createdAt: chrono.recordedAtUtc,
        chronology: chrono,
        spareParts: const [],
      );

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final workOrderCubit = context.read<WorkOrderCubit>();
      final machineCubit = context.read<MachineCubit>();
      final snackMsg = context.trArgs(
        'wo_submitted_snack',
        {'code': selectedMachine.code},
      );

      await workOrderCubit.createWorkOrder(newWorkOrder);

      if (selectedType == WorkOrderType.breakdown) {
        await machineCubit.updateMachineStatus(
          selectedMachine.id,
          MachineStatus.downtimeMaintenance,
        );
      }

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WorkOrdersListScreen(),
        ),
      );

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.downMaintenanceRed,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snackMsg,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return true;
    }
    return false;
  }
}
