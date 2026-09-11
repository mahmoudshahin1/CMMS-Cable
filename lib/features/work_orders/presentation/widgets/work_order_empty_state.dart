import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Empty state illustration displayed when no work orders match the current filters.
class WorkOrderEmptyState extends StatelessWidget {
  final bool isTech;
  final bool hasDeptScope;
  final String? departmentName;

  const WorkOrderEmptyState({
    super.key,
    required this.isTech,
    required this.hasDeptScope,
    this.departmentName,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTech
        ? context.tr('no_wo_tech')
        : (hasDeptScope
            ? context.trArgs('no_wo_dept', {'dept': departmentName ?? ''})
            : context.tr('no_work_orders'));

    final subtitle = isTech
        ? context.tr('no_wo_tech_sub')
        : context.tr('no_work_orders_sub');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 64,
              color: context.borderColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
