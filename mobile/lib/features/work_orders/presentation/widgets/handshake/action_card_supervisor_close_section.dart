import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Action button section for Supervisor to approve and close work orders (Step 5).
class ActionCardSupervisorCloseSection extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onApproveAndClose;

  const ActionCardSupervisorCloseSection({
    super.key,
    required this.isProcessing,
    required this.onApproveAndClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required: Review MTTR duration, spare parts consumed, and officially close ticket.',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isProcessing ? null : onApproveAndClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDarkMode
                ? AppColors.cyberCyan
                : context.brandPrimary,
            foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
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
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.task_alt_rounded, size: 18),
          label: Text(
            isProcessing
                ? 'Closing...'
                : 'Step 5: Approve & Close Work Order',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
