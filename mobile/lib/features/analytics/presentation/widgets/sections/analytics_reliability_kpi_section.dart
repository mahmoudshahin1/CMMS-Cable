import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/oee_calculator.dart';

/// Section showing industrial maintenance reliability KPIs: MTTR and MTBF.
class AnalyticsReliabilityKpiSection extends StatelessWidget {
  final PlantAnalyticsData data;

  const AnalyticsReliabilityKpiSection({
    super.key,
    required this.data,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
