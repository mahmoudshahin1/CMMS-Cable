import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/enums/priority.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import 'work_orders_list_screen.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../assets/domain/enums/machine_status.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/presentation/cubit/machine_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/widgets/shift_chronology_badge.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/enums/user_role.dart';

class CreateRepairRequestScreen extends StatefulWidget {
  final MachineModel? initialMachine;

  const CreateRepairRequestScreen({
    super.key,
    this.initialMachine,
  });

  @override
  State<CreateRepairRequestScreen> createState() =>
      _CreateRepairRequestScreenState();
}

class _CreateRepairRequestScreenState extends State<CreateRepairRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMachineId;
  Priority _selectedPriority = Priority.high;
  WorkOrderType _selectedType = WorkOrderType.breakdown;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _quickFaults = [
    'Wire Break on Capstan',
    'Motor Overload Inverter Trip',
    'Capstan Puller Belt Slip',
    'Zone 3 Barrel Heater Temp High',
    'Spark Tester Insulation Arc',
    'Extruder Head Pressure Drop',
    'Tension Dancer Limit Reached',
    'Take-up Traverse Mechanism Jam',
    'Cooling Trough Water Pump Trip',
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMachineId = widget.initialMachine?.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(List<MachineModel> allMachines) async {
    if (_isSubmitting) return;

    if (allMachines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.downMaintenanceRed,
          content: Text(context.tr('no_machines_registered')),
        ),
      );
      return;
    }

    final machineId = _selectedMachineId ?? allMachines.first.id;
    final selectedMachine = allMachines.firstWhere(
      (m) => m.id == machineId,
      orElse: () => allMachines.first,
    );

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final chrono = EventChronology.now();
        final workOrderId = const Uuid().v4();
        final newWorkOrder = WorkOrderModel(
          id: workOrderId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? context.trArgs('wo_request_desc', {'code': selectedMachine.code})
              : _descriptionController.text.trim(),
          machineId: selectedMachine.id,
          type: _selectedType,
          status: WorkOrderStatus.open,
          priority: _selectedPriority,
          createdAt: chrono.recordedAtUtc,
          chronology: chrono,
          spareParts: const [],
        );

        // 1. Create Work Order
        await context.read<WorkOrderCubit>().createWorkOrder(newWorkOrder);

        // 2. Set machine to downtime if breakdown
        if (_selectedType == WorkOrderType.breakdown && mounted) {
          await context.read<MachineCubit>().updateMachineStatus(
                selectedMachine.id,
                MachineStatus.downtimeMaintenance,
              );
        }

        // Navigate directly to WorkOrdersListScreen so user can immediately track their submitted order
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WorkOrdersListScreen(),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.downMaintenanceRed,
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.trArgs('wo_submitted_snack', {'code': selectedMachine.code}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(context.tr('repair_request_btn')),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkOrdersListScreen(),
                ),
              );
            },
            icon: Icon(Icons.format_list_bulleted_rounded,
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                size: 18),
            label: Text(
              context.tr('track_orders'),
              style: TextStyle(
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<MachineCubit, MachineState>(
        builder: (context, machineState) {
          final currentUser = context.watch<AuthCubit>().currentUser;
          final userDept = currentUser?.department;
          final isPlantManager = currentUser?.role == UserRole.plantManager;
          final hasDeptScope = userDept != null && !isPlantManager;

          List<MachineModel> allMachines = [];
          if (machineState is MachineLoaded) {
            allMachines = machineState.allMachines;
          }

          final List<MachineModel> selectableMachines = hasDeptScope
              ? allMachines.where((m) => m.department == userDept).toList()
              : allMachines;

          if ((_selectedMachineId == null ||
                  !selectableMachines.any((m) => m.id == _selectedMachineId)) &&
              selectableMachines.isNotEmpty) {
            _selectedMachineId = (widget.initialMachine?.id != null &&
                    selectableMachines.any((m) => m.id == widget.initialMachine!.id))
                ? widget.initialMachine!.id
                : selectableMachines.first.id;
          }

          final effectiveMachineId = selectableMachines.any((m) => m.id == _selectedMachineId)
              ? _selectedMachineId
              : (selectableMachines.isNotEmpty ? selectableMachines.first.id : null);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Shift & Operational Clock Banner
                  const ShiftChronologyBadge(),
                  const SizedBox(height: 16),

                  // 1. Machine Selection Card
                  _buildSectionHeader(
                    context: context,
                    title: context.tr('select_machine'),
                    icon: Icons.factory_rounded,
                  ),
                  const SizedBox(height: 8),

                  // Department Scope Badge
                  if (hasDeptScope)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (context.isDarkMode
                                ? AppColors.cyberCyan
                                : context.brandPrimary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: (context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: context.isDarkMode
                                  ? AppColors.cyberCyan
                                  : context.brandPrimary,
                              size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.trArgs('dept_machines_restricted', {
                                'dept': userDept.localizedName(context.isArabic),
                              }),
                              style: TextStyle(
                                color: context.isDarkMode
                                    ? AppColors.cyberCyan
                                    : context.brandPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.cardBg,
                        hint: Text(
                          context.tr('select_machine_hint'),
                          style: TextStyle(color: context.textMutedColor, fontSize: 13),
                        ),
                        value: effectiveMachineId,
                        items: selectableMachines.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? AppColors.darkNavy
                                        : AppColors.lightBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: context.borderColor),
                                  ),
                                  child: Text(
                                    m.code,
                                    style: TextStyle(
                                      color: context.isDarkMode
                                          ? AppColors.cyberCyan
                                          : context.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${m.name} (${m.department.localizedName(context.isArabic)})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: context.textPrimaryColor, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMachineId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Request Type & Priority
                  _buildSectionHeader(
                    context: context,
                    title: context.tr('type_priority_step'),
                    icon: Icons.flag_rounded,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<WorkOrderType>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
                            labelText: context.tr('request_type_label'),
                            filled: true,
                            fillColor: context.cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: context.cardBg,
                          items: WorkOrderType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.localizedName(context.isArabic),
                                  style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('severity_priority_label'),
                    style: TextStyle(color: context.textMutedColor, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: Priority.values.map((p) {
                      final isSelected = _selectedPriority == p;
                      Color pColor;
                      switch (p) {
                        case Priority.low:
                          pColor = AppColors.priorityLow;
                          break;
                        case Priority.medium:
                          pColor = AppColors.priorityMedium;
                          break;
                        case Priority.high:
                          pColor = AppColors.priorityHigh;
                          break;
                        case Priority.critical:
                          pColor = AppColors.priorityCritical;
                          break;
                      }

                      return ChoiceChip(
                        label: Text(p.localizedName(context.isArabic).toUpperCase()),
                        selected: isSelected,
                        selectedColor: pColor.withValues(alpha: 0.25),
                        backgroundColor: context.cardBg,
                        side: BorderSide(
                          color: isSelected ? pColor : context.borderColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? pColor : context.textSecondaryColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPriority = p);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 3. Quick Fault Presets
                  _buildSectionHeader(
                    context: context,
                    title: context.tr('quick_presets_step'),
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickFaults.map((fault) {
                      return ActionChip(
                        label: Text(fault),
                        backgroundColor: context.cardBg,
                        side: BorderSide(color: context.borderColor),
                        labelStyle: TextStyle(
                          color: context.isDarkMode
                              ? AppColors.cyberCyan
                              : context.brandPrimary,
                          fontSize: 11,
                        ),
                        onPressed: () {
                          setState(() {
                            _titleController.text = fault;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 4. Fault Title & Details
                  _buildSectionHeader(
                    context: context,
                    title: context.tr('fault_title_notes_step'),
                    icon: Icons.edit_note_rounded,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: context.tr('fault_title_field'),
                      hintText: context.tr('fault_title_hint'),
                      filled: true,
                      fillColor: context.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return context.tr('fault_title_error');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr('additional_notes_field'),
                      hintText: context.tr('additional_notes_hint'),
                      filled: true,
                      fillColor: context.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSubmitting ? null : () => _submitRequest(selectableMachines),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? AppColors.downMaintenanceRed
                            : AppColors.energyaAccentOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSubmitting
                              ? context.tr('submitting_request')
                              : context.tr('submit_work_order_btn'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      {required BuildContext context,
      required String title,
      required IconData icon}) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: context.isDarkMode
                ? AppColors.cyberCyan
                : context.brandPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
