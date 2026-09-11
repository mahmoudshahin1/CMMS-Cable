import 'package:flutter/material.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Top header bar of the audit timeline displaying tamper-proof seal and sort controls.
class TimelineHeaderBar extends StatelessWidget {
  final bool ascending;
  final VoidCallback onToggleSort;

  const TimelineHeaderBar({
    super.key,
    required this.ascending,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.cyberCyan : context.brandPrimary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isDark ? AppColors.cyberCyan : context.brandPrimary)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.security_rounded,
              color: isDark ? AppColors.cyberCyan : context.brandPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('audit_log_title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 11,
                      color: isDark
                          ? AppColors.runningEmerald
                          : AppColors.electricBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.tr('audit_log_tamper_proof'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.runningEmerald
                              : AppColors.electricBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: ascending
                ? context.tr('sort_newest_first')
                : context.tr('sort_oldest_first'),
            icon: Icon(
              ascending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
              color: context.textSecondaryColor,
            ),
            onPressed: onToggleSort,
          ),
        ],
      ),
    );
  }
}
