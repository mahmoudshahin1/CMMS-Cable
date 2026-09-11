import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../downtime/domain/enums/downtime_category.dart';
import '../../../../core/localization/app_strings.dart';

class DowntimeParetoCard extends StatelessWidget {
  final Map<DowntimeCategory, int> categoryMinutes;

  const DowntimeParetoCard({
    super.key,
    required this.categoryMinutes,
  });

  @override
  Widget build(BuildContext context) {
    // Sort categories by downtime minutes descending
    final sortedEntries = categoryMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalMinutes =
        categoryMinutes.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOWNTIME PARETO ANALYSIS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('pareto_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.downMaintenanceRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.trArgs('total_hours', {
                    'val': (totalMinutes / 60.0).toStringAsFixed(1),
                  }),
                  style: const TextStyle(
                    color: AppColors.downMaintenanceRed,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedEntries.take(5).map((entry) {
            final category = entry.key;
            final minutes = entry.value;
            final percentage = totalMinutes > 0
                ? (minutes / totalMinutes.toDouble())
                : 0.0;

            Color barColor;
            if (context.isDarkMode) {
              barColor = AppColors.electricBlue;
              if (category == DowntimeCategory.mechanicalBreakdown) {
                barColor = AppColors.downMaintenanceRed;
              } else if (category == DowntimeCategory.electricalBreakdown) {
                barColor = AppColors.downProcessOrange;
              } else if (category == DowntimeCategory.processSetup) {
                barColor = AppColors.cyberCyan;
              } else if (category == DowntimeCategory.plannedMaintenance) {
                barColor = AppColors.runningEmerald;
              }
            } else {
              barColor = AppColors.energyaPrimaryBlue;
              if (category == DowntimeCategory.mechanicalBreakdown) {
                barColor = AppColors.energyaAccentOrange;
              } else if (category == DowntimeCategory.electricalBreakdown) {
                barColor = AppColors.downProcessOrange;
              } else if (category == DowntimeCategory.processSetup) {
                barColor = AppColors.energyaDeepNavy;
              } else if (category == DowntimeCategory.plannedMaintenance) {
                barColor = AppColors.runningEmerald;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          category.localizedName(context.isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        context.trArgs('minutes_pct', {
                          'mins': minutes.toString(),
                          'pct': (percentage * 100).toStringAsFixed(0),
                        }),
                        style: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: context.isDarkMode
                          ? AppColors.darkNavy
                          : AppColors.energyaLightSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
