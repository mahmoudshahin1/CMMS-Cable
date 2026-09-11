import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/work_order_status.dart';

/// Horizontal filter bar for filtering work orders by status.
class WorkOrderFilterBar extends StatelessWidget {
  final WorkOrderStatus? selectedStatus;
  final ValueChanged<WorkOrderStatus?> onStatusChanged;

  const WorkOrderFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  Widget _buildChip(
    BuildContext context,
    String label,
    WorkOrderStatus? status,
  ) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: context.isDarkMode
            ? AppColors.electricBlue
            : AppColors.energyaPrimaryBlue,
        backgroundColor: context.cardBg,
        side: BorderSide(
          color: isSelected
              ? (context.isDarkMode
                  ? AppColors.cyberCyan
                  : AppColors.energyaPrimaryBlue)
              : context.borderColor,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : context.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        onSelected: (_) => onStatusChanged(status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(context, context.tr('filter_all_label'), null),
          _buildChip(
            context,
            context.tr('filter_pending_label'),
            WorkOrderStatus.open,
          ),
          _buildChip(
            context,
            context.tr('filter_assigned_label'),
            WorkOrderStatus.assigned,
          ),
          _buildChip(
            context,
            context.tr('filter_in_progress_label'),
            WorkOrderStatus.inProgress,
          ),
          _buildChip(
            context,
            context.tr('filter_completed_label'),
            WorkOrderStatus.completed,
          ),
          _buildChip(
            context,
            context.tr('filter_verified_label'),
            WorkOrderStatus.verified,
          ),
          _buildChip(
            context,
            context.tr('filter_closed_label'),
            WorkOrderStatus.verifiedClosed,
          ),
        ],
      ),
    );
  }
}
