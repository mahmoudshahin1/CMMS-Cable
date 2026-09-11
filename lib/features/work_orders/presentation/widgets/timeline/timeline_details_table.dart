import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'timeline_step_helper.dart';

/// Table displaying operational key-value details of an audit log entry.
class TimelineDetailsTable extends StatelessWidget {
  final Map<String, dynamic>? details;

  const TimelineDetailsTable({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final rawDetails = details ?? {};
    final operationalEntries = rawDetails.entries.where((entry) {
      final k = entry.key.toLowerCase();
      if (k.contains('time') ||
          k.contains('date') ||
          k == 'closedat' ||
          k == 'startedat' ||
          k == 'createdat') {
        return false;
      }
      final valStr = entry.value.toString();
      if (valStr.length >= 19 &&
          valStr.contains('T') &&
          DateTime.tryParse(valStr) != null) {
        return false;
      }
      return true;
    }).toList();

    if (operationalEntries.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: operationalEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${TimelineStepHelper.formatDetailKey(context, entry.key)}: ',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
