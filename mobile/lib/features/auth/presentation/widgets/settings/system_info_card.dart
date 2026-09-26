import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Card showing CMMS app version, Hive DB state, and corporate branding info.
class SystemInfoCard extends StatelessWidget {
  const SystemInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: context.textMutedColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('app_version'),
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'v2.4.0 (Enterprise)',
                style: TextStyle(
                  color: context.isDarkMode
                      ? AppColors.cyberCyan
                      : context.brandPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.offline_pin_rounded,
                color: AppColors.runningEmerald,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('hive_db_active'),
                  style: TextStyle(color: context.textMutedColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                color: context.isDarkMode
                    ? AppColors.cyberCyan
                    : context.brandPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('company_label'),
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
