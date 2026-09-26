import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../cubit/analytics_cubit.dart';
import '../cubit/analytics_state.dart';
import '../widgets/downtime_pareto_card.dart';
import '../widgets/oee_radial_gauge.dart';
import '../widgets/sections/analytics_department_comparison_list.dart';
import '../widgets/sections/analytics_department_filter_chips.dart';
import '../widgets/sections/analytics_oee_pillars_section.dart';
import '../widgets/sections/analytics_production_kpi_ribbon.dart';
import '../widgets/sections/analytics_reliability_kpi_section.dart';

/// Screen presenting real-time OEE analytics, production speed, scrap rate, MTTR/MTBF, and Pareto breakdown.
class PlantAnalyticsScreen extends StatelessWidget {
  const PlantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(context.tr('analytics_screen_title')),
        ),
        actions: [
          const PersonaIndicatorChip(compact: true),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('recalculate_tooltip'),
            onPressed: () {
              context.read<AnalyticsCubit>().computeAnalytics();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('oee_updated_snack')),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: context.tr('settings_title'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! AnalyticsLoaded) {
            return Center(child: Text(context.tr('computing_kpis')));
          }

          final data = state.data;
          final selectedDept = state.selectedDepartment;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AnalyticsCubit>().computeAnalytics();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnalyticsDepartmentFilterChips(selectedDept: selectedDept),
                  const SizedBox(height: 16),
                  OeeRadialGauge(oeePercentage: data.overallOee),
                  const SizedBox(height: 16),
                  AnalyticsProductionKpiRibbon(data: data),
                  const SizedBox(height: 16),
                  AnalyticsOeePillarsSection(data: data),
                  const SizedBox(height: 20),
                  AnalyticsReliabilityKpiSection(data: data),
                  const SizedBox(height: 20),
                  DowntimeParetoCard(
                    categoryMinutes: data.downtimeCategoryMinutes,
                  ),
                  const SizedBox(height: 20),
                  AnalyticsDepartmentComparisonList(
                    departmentKpis: data.departmentKpis,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
