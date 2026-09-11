import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/kpi_metric_card.dart';
import '../../../assets/domain/enums/department_type.dart';
import '../cubit/analytics_cubit.dart';
import '../cubit/analytics_state.dart';
import '../widgets/oee_radial_gauge.dart';
import '../widgets/oee_factor_card.dart';
import '../widgets/downtime_pareto_card.dart';
import '../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../auth/presentation/screens/settings_screen.dart';
import '../../../../core/localization/app_strings.dart';

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
                  // 1. Department Filter Horizontal Selector
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          context: context,
                          label: context.tr('all_depts_filter'),
                          isSelected: selectedDept == null,
                          onTap: () => context
                              .read<AnalyticsCubit>()
                              .selectDepartment(null),
                        ),
                        ...DepartmentType.values.map((dept) {
                          return _buildFilterChip(
                            context: context,
                            label: dept.localizedName(context.isArabic),
                            isSelected: selectedDept == dept,
                            onTap: () => context
                                .read<AnalyticsCubit>()
                                .selectDepartment(dept),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. High-Impact OEE Radial Gauge
                  OeeRadialGauge(oeePercentage: data.overallOee),
                  const SizedBox(height: 16),

                  // 3. Top KPI Metric Quick Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        KpiMetricCard(
                          title: 'PROD OUTPUT',
                          value: '${data.totalProductionKm.toStringAsFixed(1)}k',
                          subtitle: context.tr('prod_output_sub'),
                          icon: Icons.straighten_rounded,
                          accentColor: context.isDarkMode
                              ? AppColors.cyberCyan
                              : context.brandPrimary,
                        ),
                        const SizedBox(width: 10),
                        KpiMetricCard(
                          title: 'TOTAL DOWNTIME',
                          value: '${data.totalDowntimeHours.toStringAsFixed(1)}h',
                          subtitle: context.tr('downtime_hours_sub'),
                          icon: Icons.timer_outlined,
                          accentColor: AppColors.downMaintenanceRed,
                        ),
                        const SizedBox(width: 10),
                        KpiMetricCard(
                          title: 'SCRAP RATE',
                          value: '${data.totalScrapKm.toStringAsFixed(2)}k',
                          subtitle: context.tr('scrap_km_sub'),
                          icon: Icons.delete_sweep_rounded,
                          accentColor: AppColors.downProcessOrange,
                        ),
                        const SizedBox(width: 10),
                        KpiMetricCard(
                          title: 'PARTS COST',
                          value: '\$${data.totalMaintenanceCost.toStringAsFixed(0)}',
                          subtitle: context.tr('parts_cost_sub'),
                          icon: Icons.attach_money_rounded,
                          accentColor: AppColors.runningEmerald,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Three Pillars of OEE
                  Text(
                    context.tr('oee_pillars_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OeeFactorCard(
                    title: context.tr('availability_title'),
                    subtitle: context.isArabic
                        ? context.tr('availability_ar_sub')
                        : context.tr('availability_sub'),
                    percentage: data.availability,
                    formula: 'Operating Time / Planned Production Time',
                    icon: Icons.access_time_filled_rounded,
                    accentColor: context.isDarkMode
                        ? AppColors.electricBlue
                        : context.brandPrimary,
                  ),
                  const SizedBox(height: 10),
                  OeeFactorCard(
                    title: context.tr('performance_title'),
                    subtitle: context.isArabic
                        ? context.tr('performance_ar_sub')
                        : context.tr('performance_sub'),
                    percentage: data.performance,
                    formula: 'Actual Line Speed / Design Speed',
                    icon: Icons.speed_rounded,
                    accentColor: context.isDarkMode
                        ? AppColors.cyberCyan
                        : context.brandAccent,
                  ),
                  const SizedBox(height: 10),
                  OeeFactorCard(
                    title: context.tr('quality_title'),
                    subtitle: context.isArabic
                        ? context.tr('quality_ar_sub')
                        : context.tr('quality_sub'),
                    percentage: data.quality,
                    formula: '(Total Production - Scrap) / Total Production',
                    icon: Icons.verified_rounded,
                    accentColor: AppColors.runningEmerald,
                  ),
                  const SizedBox(height: 20),

                  // 5. Maintenance Reliability KPIs (MTTR & MTBF)
                  Text(
                    context.tr('reliability_kpis_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReliabilityCard(
                          context: context,
                          title: 'MTTR',
                          label: context.tr('mttr_label'),
                          value: context.trArgs('minutes_unit', {
                            'val': data.mttrMinutes.toStringAsFixed(0),
                          }),
                          sub: 'Mean Time To Repair',
                          icon: Icons.build_circle_rounded,
                          color: AppColors.downMaintenanceRed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReliabilityCard(
                          context: context,
                          title: 'MTBF',
                          label: context.tr('mtbf_label'),
                          value: context.trArgs('hours_unit', {
                            'val': data.mtbfHours.toStringAsFixed(1),
                          }),
                          sub: 'Mean Time Between Failures',
                          icon: Icons.shield_rounded,
                          color: AppColors.runningEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. Downtime Pareto Analysis
                  DowntimeParetoCard(
                    categoryMinutes: data.downtimeCategoryMinutes,
                  ),
                  const SizedBox(height: 20),

                  // 7. Departmental OEE Comparison
                  Text(
                    context.tr('dept_oee_compare'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...data.departmentKpis.values.map((kpi) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kpi.oee >= 85.0
                                  ? AppColors.runningEmerald
                                  : (kpi.oee >= 70.0
                                      ? AppColors.idleAmber
                                      : AppColors.downMaintenanceRed),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kpi.department.localizedName(context.isArabic),
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  context.trArgs('dept_machines_info', {
                                    'running': kpi.runningMachines.toString(),
                                    'total': kpi.totalMachines.toString(),
                                    'km': kpi.productionKm.toStringAsFixed(1),
                                  }),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${kpi.oee.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode
                    ? AppColors.electricBlue
                    : context.brandPrimary)
                : context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary)
                  : context.borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.textSecondaryColor,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReliabilityCard({
    required BuildContext context,
    required String title,
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
