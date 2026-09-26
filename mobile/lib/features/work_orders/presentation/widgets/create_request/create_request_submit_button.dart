import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Full-width submit action button for new repair request.
class CreateRequestSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback? onSubmit;

  const CreateRequestSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.isDarkMode
              ? AppColors.downMaintenanceRed
              : AppColors.energyaAccentOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isSubmitting
                ? context.tr('submitting_request')
                : context.tr('submit_work_order_btn'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
