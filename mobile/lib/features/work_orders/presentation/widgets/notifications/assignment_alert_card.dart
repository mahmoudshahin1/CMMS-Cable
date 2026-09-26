import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/machine_status.dart';
import '../../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../../auth/domain/models/user_model.dart';
import '../../../domain/enums/priority.dart';
import '../../../domain/models/work_order_model.dart';
import '../../cubit/work_order_cubit.dart';
import '../../screens/work_order_detail_screen.dart';

/// Card for urgent dispatched work orders awaiting field repair by technician.
class AssignmentAlertCard extends StatelessWidget {
  final WorkOrderModel workOrder;
  final UserModel currentUser;

  const AssignmentAlertCard({
    super.key,
    required this.workOrder,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = workOrder.priority == Priority.critical ||
        workOrder.priority == Priority.high;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isCritical ? AppColors.downMaintenanceRed : AppColors.idleAmber,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.downMaintenanceRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.trArgs('priority_label', {
                      'priority': workOrder.priority
                          .localizedName(context.isArabic)
                          .toUpperCase(),
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.downMaintenanceRed,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.trArgs(
                    'machine_label',
                    {'machine': workOrder.machineId},
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workOrder.title,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workOrder.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkOrderDetailScreen(workOrder: workOrder),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: Text(
                    context.tr('details_btn'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    final woCubit = context.read<WorkOrderCubit>();
                    final mCubit = context.read<MachineCubit>();

                    woCubit.startRepair(workOrder.id, caller: currentUser);
                    mCubit.updateMachineStatus(
                      workOrder.machineId,
                      MachineStatus.underRepair,
                    );
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkOrderDetailScreen(workOrder: workOrder),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode
                        ? AppColors.electricBlue
                        : context.brandAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    context.tr('start_repair_btn'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
