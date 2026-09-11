import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/machine_model.dart';
import '../../domain/enums/machine_status.dart';
import '../cubit/machine_cubit.dart';
import '../widgets/downtime_report_sheet.dart';
import '../widgets/overview/plant_department_filter_bar.dart';
import '../widgets/overview/plant_department_scope_banner.dart';
import '../widgets/overview/plant_factory_kpi_bar.dart';
import '../widgets/overview/plant_machine_sliver_grid.dart';
import '../widgets/overview/plant_overview_header_bar.dart';
import '../../../work_orders/presentation/screens/create_repair_request_screen.dart';

/// Main plant operations dashboard displaying machines, status KPIs, and quick breakdown reporting.
class PlantOverviewScreen extends StatelessWidget {
  const PlantOverviewScreen({super.key});

  void _showDowntimeSheet(BuildContext context, MachineModel machine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DowntimeReportSheet(machine: machine),
    );
  }

  void _handleDowntimeAction(BuildContext context, MachineModel machine) {
    if (machine.status.isDowntime) {
      _showDowntimeSheet(context, machine);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateRepairRequestScreen(
            initialMachine: machine,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => context.read<MachineCubit>().loadMachines(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: PlantOverviewHeaderBar()),
              const SliverToBoxAdapter(child: PlantDepartmentScopeBanner()),
              const SliverToBoxAdapter(child: PlantFactoryKpiBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: PlantDepartmentFilterBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              PlantMachineSliverGrid(
                onReportDowntime: (machine) =>
                    _handleDowntimeAction(context, machine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
