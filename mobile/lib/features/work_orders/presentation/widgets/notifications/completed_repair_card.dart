import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/work_order_status.dart';
import '../../../domain/models/work_order_model.dart';

/// Card showing recently repaired work order in notification log.
class CompletedRepairCard extends StatelessWidget {
  final WorkOrderModel workOrder;

  const CompletedRepairCard({
    super.key,
    required this.workOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.runningEmerald,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workOrder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${workOrder.machineId} • ${workOrder.status.localizedName(context.isArabic)}',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
