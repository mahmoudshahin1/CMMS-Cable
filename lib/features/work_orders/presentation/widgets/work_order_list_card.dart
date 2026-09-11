import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../auth/data/mock_users.dart';
import '../../domain/enums/priority.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/models/work_order_model.dart';
import '../screens/work_order_detail_screen.dart';

/// Card item for the work orders list screen.
class WorkOrderListCard extends StatelessWidget {
  final WorkOrderModel workOrder;
  final MachineModel? machine;

  const WorkOrderListCard({
    super.key,
    required this.workOrder,
    this.machine,
  });

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.critical:
        return AppColors.priorityCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(workOrder.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: color.withValues(
            alpha: context.isDarkMode ? 0.3 : 0.4,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkOrderDetailScreen(workOrder: workOrder),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.build_rounded, color: color, size: 20),
        ),
        title: Text(
          workOrder.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${machine != null ? '${machine!.name} (${machine!.code})' : 'Machine: ${workOrder.machineId}'} • ${workOrder.type.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.textMutedColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (machine != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyberCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.cyberCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      machine!.department.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cyberCyan,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.darkNavy
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    workOrder.status.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cyberCyan,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    workOrder.priority.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (workOrder.assignedToTechnicianId != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.subduedViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.subduedViolet.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.handyman_rounded,
                          size: 10,
                          color: AppColors.subduedViolet,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          MockUsers.findById(
                            workOrder.assignedToTechnicianId!,
                          ).name.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.subduedViolet,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: context.textMutedColor,
        ),
      ),
    );
  }
}
