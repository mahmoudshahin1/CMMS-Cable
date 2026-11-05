import 'package:flutter/material.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/repair_step_model.dart';
import '../../domain/models/work_order_model.dart';
import 'root_cause_maintenance_section.dart';
import 'spare_parts_consumption_section.dart';
import 'structured_repair_steps_section.dart';
import 'voice_note_recorder_widget.dart';

/// Renders the repair steps, spare parts, root cause notes, and voice attachments.
class WorkOrderRepairFormSection extends StatelessWidget {
  final WorkOrderModel workOrder;
  final bool isCompleted;
  final bool isTech;
  final TextEditingController rootCauseController;
  final TextEditingController actionsTakenController;
  final TextEditingController partNameController;
  final TextEditingController partQtyController;
  final VoidCallback onAddSparePart;
  final List<RepairStepModel> repairSteps;
  final ValueChanged<List<RepairStepModel>> onStepsChanged;
  final String? repairVoiceUrl;
  final ValueChanged<String?> onRepairVoiceUrlChanged;

  const WorkOrderRepairFormSection({
    super.key,
    required this.workOrder,
    required this.isCompleted,
    required this.isTech,
    required this.rootCauseController,
    required this.actionsTakenController,
    required this.partNameController,
    required this.partQtyController,
    required this.onAddSparePart,
    required this.repairSteps,
    required this.onStepsChanged,
    required this.repairVoiceUrl,
    required this.onRepairVoiceUrlChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = !isCompleted &&
        workOrder.status == WorkOrderStatus.inProgress &&
        isTech;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workOrder.voiceNoteUrl != null) ...[
          VoiceNoteRecorderWidget(
            label: 'Fault Voice Note (Operator)',
            initialAudioUrl: workOrder.voiceNoteUrl,
            isEditable: false,
            onAudioUrlChanged: (_) {},
          ),
          const SizedBox(height: 16),
        ],
        StructuredRepairStepsSection(
          workOrder: workOrder,
          isEditable: canEdit,
          onStepsChanged: onStepsChanged,
        ),
        const SizedBox(height: 16),
        SparePartsConsumptionSection(
          workOrder: workOrder,
          isCompleted: isCompleted,
          canAddParts: isTech,
          partNameController: partNameController,
          partQtyController: partQtyController,
          onAddSparePart: onAddSparePart,
        ),
        const SizedBox(height: 16),
        VoiceNoteRecorderWidget(
          label: 'Repair Remarks Audio (Technician)',
          workOrderId: workOrder.id,
          initialAudioUrl: repairVoiceUrl ?? workOrder.repairVoiceUrl,
          isEditable: canEdit,
          onAudioUrlChanged: onRepairVoiceUrlChanged,
        ),
        const SizedBox(height: 16),
        RootCauseMaintenanceSection(
          rootCauseController: rootCauseController,
          actionsTakenController: actionsTakenController,
          isEnabled: canEdit,
        ),
      ],
    );
  }
}
