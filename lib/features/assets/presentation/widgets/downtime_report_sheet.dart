import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../../downtime/domain/enums/downtime_category.dart';
import '../../../downtime/domain/models/downtime_log_model.dart';
import '../../../downtime/presentation/cubit/downtime_cubit.dart';
import '../cubit/machine_cubit.dart';
import '../../domain/enums/machine_status.dart';
import '../../../work_orders/presentation/cubit/work_order_cubit.dart';
import '../../../work_orders/domain/models/work_order_model.dart';
import '../../../work_orders/domain/enums/work_order_type.dart';
import '../../../work_orders/domain/enums/work_order_status.dart';
import '../../../work_orders/domain/enums/priority.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../../work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/swipe_action_button.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/widgets/shift_chronology_badge.dart';
import '../../../../core/localization/app_strings.dart';

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

  final List<String> _quickReasons = [
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
      final reason = _reasonController.text.trim().isEmpty
          ? _selectedCategory.displayName
          : _reasonController.text.trim();

      final chrono = EventChronology.now();
      final newLog = DowntimeLogModel(
        id: const Uuid().v4(),
        machineId: widget.machine.id,
        reportedById: 'OP-104',
        startTime: chrono.recordedAtUtc,
        category: _selectedCategory,
        reason: reason,
        isMaintenanceRequested: _isMaintenanceRequested,
        startChronology: chrono,
      );

      // 1. Log Downtime
      await context.read<DowntimeCubit>().reportDowntime(newLog);
      if (!mounted) return;

      // 2. Automatically create Work Order so it ALWAYS appears in Track Orders
      if (_isMaintenanceRequested || _selectedCategory.isMaintenance) {
        final workOrderId = const Uuid().v4();
        final desc = context.trArgs('downtime_wo_desc', {
          'name': widget.machine.name,
          'code': widget.machine.code,
          'dept': widget.machine.department.localizedName(context.isArabic),
          'reason': reason,
        });
        final newWorkOrder = WorkOrderModel(
          id: workOrderId,
          title: '${widget.machine.code}: $reason',
          description: desc,
          machineId: widget.machine.id,
          type: WorkOrderType.breakdown,
          status: WorkOrderStatus.open,
          priority: Priority.high,
          createdAt: chrono.recordedAtUtc,
          chronology: chrono,
          spareParts: const [],
        );
        if (mounted) {
          await context.read<WorkOrderCubit>().createWorkOrder(newWorkOrder);
        }
      }

      // 3. Update Machine Status
      if (mounted) {
        await context.read<MachineCubit>().updateMachineStatus(
              widget.machine.id,
              _selectedCategory.isMaintenance
                  ? MachineStatus.downtimeMaintenance
                  : MachineStatus.downtimeProcess,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.downMaintenanceRed,
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.trArgs('downtime_logged_snack', {
                      'code': widget.machine.code,
                    }),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: context.tr('track_orders_btn'),
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkOrdersListScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
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

            // Header Identity Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? AppColors.slateCard
                    : AppColors.energyaLightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.downMaintenanceRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.downMaintenanceRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.machine.code} - ${widget.machine.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.machine.department.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.isDarkMode
                                ? AppColors.cyberCyan
                                : context.brandPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Automated Shift & Live Plant Chronology Banner
            const ShiftChronologyBadge(),
            const SizedBox(height: 16),

            Text(
              '1. SELECT DOWNTIME CATEGORY',
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Category Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DowntimeCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat;
                        _isMaintenanceRequested = cat.isMaintenance;
                      });
                    }
                  },
                  selectedColor: cat.isMaintenance
                      ? AppColors.downMaintenanceRed
                      : AppColors.downProcessOrange,
                  backgroundColor: context.isDarkMode
                      ? AppColors.slateCard
                      : AppColors.energyaLightSurface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.textSecondaryColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(
              '2. QUICK REASON CHIPS / NOTES',
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Quick Reasons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((reason) {
                return ActionChip(
                  label: Text(reason),
                  backgroundColor: context.isDarkMode
                      ? AppColors.slateCard
                      : AppColors.energyaLightSurface,
                  side: BorderSide(color: context.borderColor),
                  labelStyle: TextStyle(
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    fontSize: 11,
                  ),
                  onPressed: () {
                    setState(() {
                      _reasonController.text = reason;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter specific downtime cause / notes...',
                hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
                filled: true,
                fillColor: context.isDarkMode
                    ? AppColors.slateCard
                    : AppColors.energyaLightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Maintenance Request Switch
            SwitchListTile(
              value: _isMaintenanceRequested,
              onChanged: (val) => setState(() => _isMaintenanceRequested = val),
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

            // Button to open Full Repair Request Form
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
                        : context.brandPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: const Icon(Icons.assignment_rounded, size: 18),
              label: Text(
                context.tr('detailed_wo_btn'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 14),

            // Swipe Action Confirmation Button
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
