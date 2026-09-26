import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Card showing live elapsed Mean Time To Repair (MTTR) while repair is in progress.
class LiveMttrTimerCard extends StatelessWidget {
  final String formattedTimer;

  const LiveMttrTimerCard({
    super.key,
    required this.formattedTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.darkNavy : AppColors.energyaWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDarkMode
              ? AppColors.electricBlue
              : AppColors.energyaPrimaryBlue,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.04,
            ),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE ELAPSED REPAIR TIME (MTTR)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Technician Working...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.brandAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedTimer,
              style: TextStyle(
                color: context.brandPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
