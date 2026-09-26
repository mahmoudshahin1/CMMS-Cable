import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/work_order_model.dart';
import '../../screens/work_order_detail_screen.dart';

/// Card showing actively serviced work order with quick tracking link.
class InProgressRepairCard extends StatelessWidget {
  final WorkOrderModel workOrder;

  const InProgressRepairCard({
    super.key,
    required this.workOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (context.isDarkMode
                  ? AppColors.electricBlue
                  : context.brandPrimary)
              .withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: context.isDarkMode
              ? AppColors.electricBlue
              : context.brandPrimary,
          child: const Icon(
            Icons.build_circle_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          workOrder.title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          context.trArgs(
            'repair_in_progress_banner',
            {'machine': workOrder.machineId},
          ),
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.5),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      WorkOrderDetailScreen(workOrder: workOrder),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDarkMode
                  ? AppColors.slateBorder
                  : context.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.tr('track_btn'),
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
