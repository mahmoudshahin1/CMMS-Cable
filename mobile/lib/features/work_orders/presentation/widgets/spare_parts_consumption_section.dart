import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';

/// Section rendering the spare parts consumed on a work order,
/// plus the input form for maintenance technicians when repair is active.
class SparePartsConsumptionSection extends StatelessWidget {
  final WorkOrderModel workOrder;
  final bool isCompleted;
  final bool canAddParts;
  final TextEditingController partNameController;
  final TextEditingController partQtyController;
  final VoidCallback onAddSparePart;

  const SparePartsConsumptionSection({
    super.key,
    required this.workOrder,
    required this.isCompleted,
    required this.canAddParts,
    required this.partNameController,
    required this.partQtyController,
    required this.onAddSparePart,
  });

  @override
  Widget build(BuildContext context) {
    final showInputForm = !isCompleted &&
        workOrder.status == WorkOrderStatus.inProgress &&
        canAddParts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPARE PARTS CONSUMED',
          style: TextStyle(
            color: context.isDarkMode
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        if (showInputForm) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: partNameController,
                  style:
                      TextStyle(color: context.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Part name (e.g. O-Ring)',
                    hintStyle: TextStyle(color: context.textMutedColor),
                    filled: true,
                    fillColor: context.cardBg,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: partQtyController,
                  keyboardType: TextInputType.number,
                  style:
                      TextStyle(color: context.textPrimaryColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: TextStyle(color: context.textMutedColor),
                    filled: true,
                    fillColor: context.cardBg,
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onAddSparePart,
                icon: Icon(
                  Icons.add_circle,
                  color: context.brandPrimary,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: workOrder.spareParts.map((part) {
            return Chip(
              avatar: Icon(
                Icons.settings_suggest,
                size: 14,
                color: context.brandPrimary,
              ),
              label: Text(
                '${part.name} (x${part.quantityUsed})',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 12,
                ),
              ),
              backgroundColor: context.isDarkMode
                  ? AppColors.slateCard
                  : AppColors.energyaLightSurface,
              side: BorderSide(color: context.borderColor),
            );
          }).toList(),
        ),
      ],
    );
  }
}
