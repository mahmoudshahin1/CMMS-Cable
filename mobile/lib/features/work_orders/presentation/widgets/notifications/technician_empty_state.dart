import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Clean placeholder view when the technician has no tickets assigned.
class TechnicianEmptyState extends StatelessWidget {
  const TechnicianEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_rounded,
            size: 56,
            color: AppColors.runningEmerald.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_tickets_assigned_tech'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_tickets_assigned_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
