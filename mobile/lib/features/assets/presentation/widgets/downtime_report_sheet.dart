import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shift_chronology_badge.dart';
import '../../../../core/widgets/swipe_action_button.dart';
import '../../../downtime/domain/enums/downtime_category.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../domain/models/machine_model.dart';
import 'downtime_sheet/downtime_category_selector.dart';
import 'downtime_sheet/downtime_machine_identity_card.dart';
import 'downtime_sheet/downtime_reason_notes_section.dart';
import 'downtime_sheet/downtime_sheet_controller.dart';

/// Modal bottom sheet for immediate shop-floor logging of an unplanned downtime event.
class DowntimeReportSheet extends StatefulWidget {
  final MachineModel machine;

  const DowntimeReportSheet({super.key, required this.machine});

  @override
  State<DowntimeReportSheet> createState() => _DowntimeReportSheetState();
}

class _DowntimeReportSheetState extends State<DowntimeReportSheet> {
  DowntimeCategory _selectedCategory = DowntimeCategory.mechanicalBreakdown;
  final TextEditingController _reasonController = TextEditingController();
  bool _isMaintenanceRequested = true;
  bool _isSubmitting = false;

  final List<String> _quickReasons = const [
    'Wire Break',
    'Crosshead Temp High',
    'Motor Overload Trip',
    'Material Supply Shortage',
    'Extruder Pressure Drop',
    'Capstan Belt Slip',
    'Power Voltage Dip',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDowntime() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await DowntimeSheetController.submitDowntime(
        context: context,
        machine: widget.machine,
        category: _selectedCategory,
        reasonText: _reasonController.text,
        isMaintenanceRequested: _isMaintenanceRequested,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.borderColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DowntimeMachineIdentityCard(machine: widget.machine),
            const SizedBox(height: 12),
            const ShiftChronologyBadge(),
            const SizedBox(height: 16),
            DowntimeCategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) {
                setState(() {
                  _selectedCategory = cat;
                  _isMaintenanceRequested = cat.isMaintenance;
                });
              },
            ),
            const SizedBox(height: 20),
            DowntimeReasonNotesSection(
              reasonController: _reasonController,
              quickReasons: _quickReasons,
              onQuickReasonSelected: (reason) {
                setState(() => _reasonController.text = reason);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isMaintenanceRequested,
              onChanged: (val) =>
                  setState(() => _isMaintenanceRequested = val),
              activeThumbColor: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Request Maintenance Work Order',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Notify Maintenance Supervisor & Electrical/Mechanical Technicians',
                style: TextStyle(color: context.textMutedColor, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateRepairRequestScreen(
                      initialMachine: widget.machine,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                side: BorderSide(
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.assignment_rounded, size: 18),
              label: Text(
                context.tr('detailed_wo_btn'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SwipeActionButton(
              label: 'Swipe to Submit Downtime',
              onSwipeCompleted: _submitDowntime,
              backgroundColor: _selectedCategory.isMaintenance
                  ? AppColors.downMaintenanceRed
                  : AppColors.downProcessOrange,
            ),
          ],
        ),
      ),
    );
  }
}
