import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/work_order_model.dart';
import '../cubit/work_order_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';

class AssignTechnicianDialog extends StatefulWidget {
  final WorkOrderModel workOrder;

  const AssignTechnicianDialog({super.key, required this.workOrder});

  static Future<void> show(BuildContext context, WorkOrderModel workOrder) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignTechnicianDialog(workOrder: workOrder),
    );
  }

  @override
  State<AssignTechnicianDialog> createState() => _AssignTechnicianDialogState();
}

class _AssignTechnicianDialogState extends State<AssignTechnicianDialog> {
  String? _selectedSpeciality;
  List<UserModel> _technicians = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = getIt<AuthRepository>();
      final techs = await repo.getUsersByRole(
        'TECHNICIAN',
        speciality: _selectedSpeciality,
      );
      if (mounted) {
        setState(() {
          _technicians = techs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل قائمة الفنيين: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supervisor = context.read<AuthCubit>().currentUser;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.borderColor, width: 1.5),
          left: BorderSide(color: context.borderColor, width: 1.5),
          right: BorderSide(color: context.borderColor, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20, left: 16, right: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (context.isDarkMode
                            ? AppColors.cyberCyan
                            : context.brandPrimary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_ind_rounded,
                    color: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch & Assign Technician',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Step 2: Ticket for ${widget.workOrder.machineId}',
                        style: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: context.textMutedColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Specialization Filter Tabs
            Row(
              children: [
                _buildSpecialityChip('All Techs', null),
                const SizedBox(width: 8),
                _buildSpecialityChip('Electrical', 'Electrical'),
                const SizedBox(width: 8),
                _buildSpecialityChip('Mechanical', 'Mechanical'),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Technician List
            Flexible(
              child: _buildTechnicianList(supervisor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianList(UserModel? supervisor) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMutedColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTechnicians,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_technicians.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, color: context.textMutedColor, size: 40),
              const SizedBox(height: 12),
              Text(
                'لا يوجد فنيون متاحون',
                style: TextStyle(color: context.textMutedColor),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _technicians.map((tech) {
          final isCurrent = widget.workOrder.assignedToTechnicianId == tech.id;
          final isElec = tech.speciality?.toLowerCase() == 'electrical';
          final accentColor = context.isDarkMode
              ? (isElec ? AppColors.electricBlue : AppColors.cyberCyan)
              : (isElec ? AppColors.energyaPrimaryBlue : AppColors.energyaAccentOrange);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? accentColor.withValues(alpha: 0.12)
                  : (context.isDarkMode ? AppColors.slateCard : AppColors.energyaLightSurface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? accentColor : context.borderColor,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: accentColor.withValues(alpha: 0.2),
                child: Icon(
                  isElec ? Icons.electric_bolt_rounded : Icons.precision_manufacturing_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      tech.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tech.speciality?.toUpperCase() ?? 'TECH',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Department: ${tech.department?.name.toUpperCase() ?? 'PLANT'}',
                style: TextStyle(color: context.textMutedColor, fontSize: 11.5),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  context.read<WorkOrderCubit>().assignTechnician(
                        widget.workOrder.id,
                        tech.id,
                        supervisor?.id ?? 'supervisor',
                        caller: supervisor,
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dispatched ticket to ${tech.name}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: context.isDarkMode
                          ? AppColors.slateCard
                          : AppColors.energyaDeepNavy,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecialityChip(String label, String? speciality) {
    final isSelected = _selectedSpeciality == speciality;
    final primary = context.brandPrimary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primary,
      backgroundColor: context.isDarkMode ? AppColors.slateCard : AppColors.energyaLightSurface,
      side: BorderSide(color: isSelected ? primary : context.borderColor),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.textMutedColor,
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _selectedSpeciality = speciality;
        });
        _loadTechnicians();
      },
    );
  }
}
