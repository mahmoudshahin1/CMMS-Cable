import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/repair_step_model.dart';

/// Renders a single row representing a recorded repair step.
class RepairStepItemTile extends StatelessWidget {
  final int index;
  final RepairStepModel step;
  final bool isEditable;
  final VoidCallback? onRemove;

  const RepairStepItemTile({
    super.key,
    required this.index,
    required this.step,
    required this.isEditable,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: context.brandPrimary.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: context.brandPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (step.partName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Part: ${step.partName}${step.quantity != null ? ' (x${step.quantity})' : ''}',
                    style: TextStyle(color: context.brandPrimary, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (isEditable && onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: AppColors.downMaintenanceRed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

