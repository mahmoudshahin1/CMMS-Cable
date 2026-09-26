import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/kpi_metric_card.dart';
import '../../../domain/oee_calculator.dart';

/// Horizontal scroll ribbon showing top metrics: Production Output, Total Downtime, Scrap, and Parts Cost.
class AnalyticsProductionKpiRibbon extends StatelessWidget {
  final PlantAnalyticsData data;

  const AnalyticsProductionKpiRibbon({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}
