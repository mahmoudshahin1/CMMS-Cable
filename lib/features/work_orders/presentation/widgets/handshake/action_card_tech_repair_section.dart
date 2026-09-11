import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/models/user_model.dart';
import '../../../domain/enums/work_order_status.dart';
import '../../../domain/models/work_order_model.dart';

/// Action button section for Maintenance Technician to start or complete repair operations.
class ActionCardTechRepairSection extends StatelessWidget {
  final WorkOrderModel workOrder;
  final UserModel user;
  final bool isProcessing;
  final VoidCallback onStartRepair;
  final VoidCallback onCompleteRepair;

  const ActionCardTechRepairSection({
    super.key,
    required this.workOrder,
    required this.user,
    required this.isProcessing,
    required this.onStartRepair,
    required this.onCompleteRepair,
  });

  @override
  Widget build(BuildContext context) {
    if (workOrder.status == WorkOrderStatus.assigned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Required: Accept ticket and commence on-site diagnostic & repair.',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isProcessing ? null : onStartRepair,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.electricBlue
                  : context.brandAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              isProcessing
                  ? 'Starting Repair...'
                  : 'Step 3: Start Repair (Begin MTTR)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required: Record replaced spare parts and root cause, then complete field repair.',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isProcessing ? null : onCompleteRepair,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.runningEmerald,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: Text(
            isProcessing ? 'Completing...' : 'Complete Field Repair',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
