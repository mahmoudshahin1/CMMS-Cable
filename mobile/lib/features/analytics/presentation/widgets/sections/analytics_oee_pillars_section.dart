import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/oee_calculator.dart';
import '../oee_factor_card.dart';

/// Section rendering the three foundational pillars of OEE: Availability, Performance, and Quality.
class AnalyticsOeePillarsSection extends StatelessWidget {
  final PlantAnalyticsData data;

  const AnalyticsOeePillarsSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}
