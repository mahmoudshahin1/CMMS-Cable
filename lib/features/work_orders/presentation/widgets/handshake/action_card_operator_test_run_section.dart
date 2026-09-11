import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Action button section for Line Operator to confirm machine test run (Step 4).
class ActionCardOperatorTestRunSection extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onConfirmTestRun;

  const ActionCardOperatorTestRunSection({
    super.key,
    required this.isProcessing,
    required this.onConfirmTestRun,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required: Perform field line test run with raw material and verify stable operation.',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isProcessing ? null : onConfirmTestRun,
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
              : const Icon(Icons.fact_check_rounded, size: 18),
          label: Text(
            isProcessing
                ? 'Verifying...'
                : 'Step 4: Confirm Test Run & Line Ready',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
