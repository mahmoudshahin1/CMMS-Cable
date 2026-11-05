import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/repair_step_model.dart';
import '../../domain/models/work_order_model.dart';
import 'repair_step_item_tile.dart';

/// Interactive UI section for viewing and recording structured repair steps.
class StructuredRepairStepsSection extends StatefulWidget {
  final WorkOrderModel workOrder;
  final bool isEditable;
  final ValueChanged<List<RepairStepModel>> onStepsChanged;

  const StructuredRepairStepsSection({
    super.key,
    required this.workOrder,
    required this.isEditable,
    required this.onStepsChanged,
  });

  @override
  State<StructuredRepairStepsSection> createState() =>
      _StructuredRepairStepsSectionState();
}

class _StructuredRepairStepsSectionState
    extends State<StructuredRepairStepsSection> {
  late final List<RepairStepModel> _steps;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _partQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _steps = List<RepairStepModel>.from(widget.workOrder.repairSteps);
  }

  @override
  void dispose() {
    _descController.dispose();
    _partNameController.dispose();
    _partQtyController.dispose();
    super.dispose();
  }

  void _addStep() {
    final desc = _descController.text.trim();
    if (desc.isEmpty) return;

    final part = _partNameController.text.trim();
    final qty = int.tryParse(_partQtyController.text.trim());

    final step = RepairStepModel(
      id: 'step-${DateTime.now().millisecondsSinceEpoch}',
      description: desc,
      partName: part.isNotEmpty ? part : null,
      quantity: qty,
      completedAt: DateTime.now(),
    );

    setState(() {
      _steps.add(step);
      _descController.clear();
      _partNameController.clear();
      _partQtyController.clear();
    });
    widget.onStepsChanged(List.unmodifiable(_steps));
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
    widget.onStepsChanged(List.unmodifiable(_steps));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded, size: 16, color: context.brandPrimary),
            const SizedBox(width: 6),
            Text(
              'STRUCTURED REPAIR STEPS',
              style: TextStyle(
                color: context.isDarkMode
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${_steps.length} ${context.isArabic ? "خطوات" : "steps"}',
              style: TextStyle(color: context.textMutedColor, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.isEditable) _buildStepInputCard(context),
        if (_steps.isEmpty && !widget.isEditable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: Text(
              'No structured repair steps recorded for this work order.',
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_steps.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(
            _steps.length,
            (i) => RepairStepItemTile(
              index: i,
              step: _steps[i],
              isEditable: widget.isEditable,
              onRemove: () => _removeStep(i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepInputCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _descController,
            style: TextStyle(color: context.textPrimaryColor, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Step action (e.g. Replaced carbon brushes)',
              hintStyle: TextStyle(color: context.textMutedColor),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: context.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _partNameController,
                  style: TextStyle(
                      color: context.textPrimaryColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Part name (optional)',
                    hintStyle: TextStyle(color: context.textMutedColor),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _partQtyController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      color: context.textPrimaryColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    hintStyle: TextStyle(color: context.textMutedColor),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brandPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
