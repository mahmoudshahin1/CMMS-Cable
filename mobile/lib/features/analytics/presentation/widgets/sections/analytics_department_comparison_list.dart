import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../assets/domain/enums/department_type.dart';
import '../../../domain/oee_calculator.dart';

/// Comparative OEE breakdown cards across all production and maintenance departments.
class AnalyticsDepartmentComparisonList extends StatelessWidget {
  final Map<DepartmentType, DepartmentKpi> departmentKpis;

  const AnalyticsDepartmentComparisonList({
    super.key,
    required this.departmentKpis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('dept_oee_compare'),
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...departmentKpis.values.map((kpi) {
          final oeeColor = kpi.oee >= 85.0
              ? AppColors.runningEmerald
              : (kpi.oee >= 70.0
                  ? AppColors.idleAmber
                  : AppColors.downMaintenanceRed);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    color: oeeColor,
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
      ],
    );
  }
}
