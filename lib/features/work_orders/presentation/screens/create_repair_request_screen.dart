import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shift_chronology_badge.dart';
import '../../../assets/domain/enums/machine_status.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../assets/presentation/cubit/machine_cubit.dart';
import '../../../assets/presentation/cubit/machine_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/enums/priority.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../widgets/create_request/create_request_details_fields.dart';
import '../widgets/create_request/create_request_machine_selector.dart';
import '../widgets/create_request/create_request_quick_presets_section.dart';
import '../widgets/create_request/create_request_submit_button.dart';
import '../widgets/create_request/create_request_type_priority_section.dart';
import 'work_orders_list_screen.dart';

/// Screen allowing operators and supervisors to log a new breakdown or PM work order.
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

  final List<String> _quickFaults = const [
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
              ? context
                  .trArgs('wo_request_desc', {'code': selectedMachine.code})
              : _descriptionController.text.trim(),
          machineId: selectedMachine.id,
          type: _selectedType,
          status: WorkOrderStatus.open,
          priority: _selectedPriority,
          createdAt: chrono.recordedAtUtc,
          chronology: chrono,
          spareParts: const [],
        );

        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        final workOrderCubit = context.read<WorkOrderCubit>();
        final machineCubit = context.read<MachineCubit>();
        final snackMsg = context.trArgs(
          'wo_submitted_snack',
          {'code': selectedMachine.code},
        );

        // 1. Create Work Order
        await workOrderCubit.createWorkOrder(newWorkOrder);

        // 2. Set machine to downtime if breakdown
        if (_selectedType == WorkOrderType.breakdown) {
          await machineCubit.updateMachineStatus(
            selectedMachine.id,
            MachineStatus.downtimeMaintenance,
          );
        }

        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WorkOrdersListScreen(),
          ),
        );

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.downMaintenanceRed,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    snackMsg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
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
            icon: Icon(
              Icons.format_list_bulleted_rounded,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
              size: 18,
            ),
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
                    selectableMachines
                        .any((m) => m.id == widget.initialMachine!.id))
                ? widget.initialMachine!.id
                : selectableMachines.first.id;
          }

          final effectiveMachineId =
              selectableMachines.any((m) => m.id == _selectedMachineId)
                  ? _selectedMachineId
                  : (selectableMachines.isNotEmpty
                      ? selectableMachines.first.id
                      : null);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShiftChronologyBadge(),
                  const SizedBox(height: 16),
                  CreateRequestMachineSelector(
                    selectableMachines: selectableMachines,
                    selectedMachineId: effectiveMachineId,
                    userDept: userDept,
                    hasDeptScope: hasDeptScope,
                    onMachineChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMachineId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  CreateRequestTypePrioritySection(
                    selectedType: _selectedType,
                    onTypeChanged: (t) => setState(() => _selectedType = t),
                    selectedPriority: _selectedPriority,
                    onPriorityChanged: (p) =>
                        setState(() => _selectedPriority = p),
                  ),
                  const SizedBox(height: 20),
                  CreateRequestQuickPresetsSection(
                    quickFaults: _quickFaults,
                    onFaultSelected: (fault) {
                      setState(() => _titleController.text = fault);
                    },
                  ),
                  const SizedBox(height: 20),
                  CreateRequestDetailsFields(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                  ),
                  const SizedBox(height: 28),
                  CreateRequestSubmitButton(
                    isSubmitting: _isSubmitting,
                    onSubmit: () => _submitRequest(selectableMachines),
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
}
