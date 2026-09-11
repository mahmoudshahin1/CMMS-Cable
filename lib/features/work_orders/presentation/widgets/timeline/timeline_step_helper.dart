import 'package:flutter/material.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Helper utilities for timeline step icons, colors, localized titles, and field keys.
class TimelineStepHelper {
  const TimelineStepHelper._();

  static Color getStepColor(String stepName) {
    switch (stepName) {
      case 'REPORTED':
        return AppColors.downProcessOrange;
      case 'ASSIGNED':
        return AppColors.electricBlue;
      case 'REPAIR_STARTED':
        return AppColors.underRepairPurple;
      case 'SPARE_PART_ADDED':
        return AppColors.idleAmber;
      case 'REPAIR_COMPLETED':
        return AppColors.runningEmerald;
      case 'TEST_RUN_PASSED':
        return AppColors.cyberCyan;
      case 'CLOSED':
        return AppColors.runningEmerald;
      default:
        return AppColors.slateLight;
    }
  }

  static IconData getStepIcon(String stepName) {
    switch (stepName) {
      case 'REPORTED':
        return Icons.report_problem_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'REPAIR_STARTED':
        return Icons.build_circle_rounded;
      case 'SPARE_PART_ADDED':
        return Icons.inventory_2_rounded;
      case 'REPAIR_COMPLETED':
        return Icons.check_circle_outline_rounded;
      case 'TEST_RUN_PASSED':
        return Icons.fact_check_rounded;
      case 'CLOSED':
        return Icons.verified_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  static String getLocalizedStepTitle(BuildContext context, String stepName) {
    switch (stepName) {
      case 'REPORTED':
        return context.tr('timeline_reported');
      case 'ASSIGNED':
        return context.tr('timeline_assigned');
      case 'REPAIR_STARTED':
        return context.tr('timeline_started');
      case 'SPARE_PART_ADDED':
        return context.tr('timeline_spare_part');
      case 'REPAIR_COMPLETED':
        return context.tr('timeline_completed');
      case 'TEST_RUN_PASSED':
        return context.tr('timeline_test_run');
      case 'CLOSED':
        return context.tr('timeline_closed');
      default:
        return stepName;
    }
  }

  static Color getRoleBadgeColor(String role) {
    if (role.contains('OPERATOR')) return AppColors.downProcessOrange;
    if (role.contains('TECH')) return AppColors.electricBlue;
    if (role.contains('SUPERVISOR')) return AppColors.underRepairPurple;
    if (role.contains('MANAGER')) return AppColors.runningEmerald;
    return AppColors.slateLight;
  }

  static String formatDetailKey(BuildContext context, String key) {
    switch (key) {
      case 'machineId':
        return context.tr('field_machine_code');
      case 'priority':
        return context.tr('field_priority');
      case 'type':
        return context.tr('field_type');
      case 'technicianId':
        return context.tr('field_technician');
      case 'supervisorId':
        return context.tr('field_supervisor');
      case 'startedAt':
        return context.tr('field_start_time');
      case 'rootCause':
        return context.tr('field_root_cause');
      case 'actionsTaken':
        return context.tr('field_actions_taken');
      case 'partNumber':
        return context.tr('field_part_no');
      case 'name':
        return context.tr('field_part_name');
      case 'quantity':
        return context.tr('field_qty');
      case 'unitCost':
        return context.tr('field_unit_price');
      case 'totalSparePartsUsed':
        return context.tr('field_spare_parts');
      case 'testRunResult':
        return context.tr('field_test_run');
      case 'closedAt':
        return context.tr('field_close_date');
      default:
        return key;
    }
  }
}
