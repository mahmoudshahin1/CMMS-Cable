import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/work_order_model.dart';
import '../assign_technician_dialog.dart';

/// Action button section for Maintenance Supervisor to dispatch a technician (Step 2).
class ActionCardSupervisorAssignSection extends StatelessWidget {
  final WorkOrderModel workOrder;
  final bool isProcessing;

  const ActionCardSupervisorAssignSection({
    super.key,
    required this.workOrder,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required: Triage breakdown and dispatch an Electrical or Mechanical technician.',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () => AssignTechnicianDialog.show(context, workOrder),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDarkMode
                ? AppColors.subduedViolet
                : context.brandPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text(
            'Step 2: Assign Technician',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
