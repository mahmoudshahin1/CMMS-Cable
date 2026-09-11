import 'package:flutter/material.dart';
import '../../domain/models/work_order_activity_log.dart';
import '../../domain/models/work_order_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/chronology/plant_shift.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/localization/app_strings.dart';

class WorkOrderActivityTimelineWidget extends StatefulWidget {
  final List<WorkOrderActivityLog> activityLogs;
  final WorkOrderModel? workOrder;

  const WorkOrderActivityTimelineWidget({
    super.key,
    required this.activityLogs,
    this.workOrder,
  });

  @override
  State<WorkOrderActivityTimelineWidget> createState() =>
      _WorkOrderActivityTimelineWidgetState();
}

class _WorkOrderActivityTimelineWidgetState
    extends State<WorkOrderActivityTimelineWidget> {
  bool _ascending = false; // default newest first for quick field access

  Color _getStepColor(String stepName) {
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

  IconData _getStepIcon(String stepName) {
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

  String _getLocalizedStepTitle(BuildContext context, String stepName) {
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

  Color _getRoleBadgeColor(String role) {
    if (role.contains('OPERATOR')) return AppColors.downProcessOrange;
    if (role.contains('TECH')) return AppColors.electricBlue;
    if (role.contains('SUPERVISOR')) return AppColors.underRepairPurple;
    if (role.contains('MANAGER')) return AppColors.runningEmerald;
    return AppColors.slateLight;
  }

  String _formatDetailKey(BuildContext context, String key) {
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

  Widget _buildCrossShiftBanner(BuildContext context, bool isDark) {
    final originChrono = widget.workOrder?.effectiveChronology ??
        (widget.activityLogs.isNotEmpty
            ? widget.activityLogs.first.effectiveChronology
            : null);
    if (originChrono == null) return const SizedBox.shrink();

    final currentOrEndChrono = widget.activityLogs.isNotEmpty
        ? widget.activityLogs.last.effectiveChronology
        : EventChronology.now();

    final isCross = widget.workOrder?.isCrossShift ??
        currentOrEndChrono.isCrossShiftFrom(originChrono);

    if (!isCross) return const SizedBox.shrink();

    final originShift = originChrono.activeShift;
    final currentShift = currentOrEndChrono.activeShift;

    final startUtc = originChrono.recordedAtUtc;
    final endUtc = widget.workOrder?.completedAt?.toUtc() ??
        (currentOrEndChrono.recordedAtUtc);
    final duration = endUtc.isAfter(startUtc)
        ? endUtc.difference(startUtc)
        : Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationFormatted = '${hours}h ${minutes}m';

    final startTimeFormatted = originChrono.plantTimeFormatted.length >= 16
        ? originChrono.plantTimeFormatted.substring(11, 16)
        : originChrono.plantTimeFormatted;

    final shiftMinutes =
        EventChronology.computeDowntimeMinutesPerShift(startUtc, endUtc);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.underRepairPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.underRepairPurple.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.underRepairPurple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.underRepairPurple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('cross_shift_title'),
                  style: const TextStyle(
                    color: AppColors.underRepairPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.trArgs('cross_shift_start', {
              'time': startTimeFormatted,
              'shift': originShift.localizedName(context.isArabic),
            }),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.trArgs('cross_shift_extended', {
              'shift': currentShift.localizedName(context.isArabic),
              'time': startTimeFormatted,
              'duration': durationFormatted,
            }),
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('cross_shift_oee_dist'),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: shiftMinutes.entries
                .where((e) => e.value > 0)
                .map((entry) {
              final s = entry.key;
              final mins = entry.value;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: s.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  context.trArgs('shift_minutes', {
                    'label': s.localizedShortLabel(context.isArabic),
                    'mins': mins.toString(),
                  }),
                  style: TextStyle(
                    color: s.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final logs = List<WorkOrderActivityLog>.from(widget.activityLogs);
    if (!_ascending) {
      logs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    } else {
      logs.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Audit Seal
          Padding(
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
                      color:
                          (isDark ? AppColors.cyberCyan : context.brandPrimary)
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
                  tooltip: _ascending
                      ? context.tr('sort_newest_first')
                      : context.tr('sort_oldest_first'),
                  icon: Icon(
                    _ascending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 20,
                    color: context.textSecondaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _ascending = !_ascending;
                    });
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // Cross-Shift Warning & OEE Breakdown Banner (if applicable)
          _buildCrossShiftBanner(context, isDark),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 40,
                      color: context.textMutedColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('no_events_yet'),
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 17),
                child: Container(
                  height: 16,
                  width: 2,
                  color: context.borderColor,
                ),
              ),
              itemBuilder: (context, index) {
                final log = logs[index];
                final stepColor = _getStepColor(log.stepName);
                final roleColor = _getRoleBadgeColor(log.performedByRole);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Node
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: stepColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: stepColor, width: 2),
                      ),
                      child: Icon(
                        _getStepIcon(log.stepName),
                        color: stepColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkNavy.withValues(alpha: 0.6)
                              : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stepColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Step Title + Role Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getLocalizedStepTitle(context, log.stepName),
                                    style: TextStyle(
                                      color: stepColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: roleColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    log.performedByRole,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Performed By Info
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 13,
                                  color: context.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    log.performedByName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '(${log.performedByEmail})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textMutedColor,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Action Summary
                            Text(
                              log.actionSummary,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),

                            // Operational Details (if any, excluding redundant timestamps)
                            Builder(
                              builder: (context) {
                                final rawDetails = log.details ?? {};
                                final operationalEntries =
                                    rawDetails.entries.where((entry) {
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

                                if (operationalEntries.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.slateCard
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: context.borderColor,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          operationalEntries.map((entry) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_formatDetailKey(context, entry.key)}: ',
                                                style: TextStyle(
                                                  color: context
                                                      .textSecondaryColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${entry.value}',
                                                  style: TextStyle(
                                                    color: context
                                                        .textPrimaryColor,
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
                              },
                            ),

                            const SizedBox(height: 8),
                            // Dual Timestamp & Shift Context
                            Builder(
                              builder: (context) {
                                final chrono = log.effectiveChronology;
                                final shift = chrono.activeShift;
                                final shiftColor = shift.color;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : AppColors.slateBorder
                                            .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: shiftColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: shiftColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: shiftColor
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(shift.icon,
                                                    size: 11,
                                                    color: shiftColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  shift.localizedShortLabel(context.isArabic),
                                                  style: TextStyle(
                                                    color: shiftColor,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            shift.localizedName(context.isArabic),
                                            style: TextStyle(
                                              color: shiftColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            context.trArgs(
                                                'production_date_label', {
                                              'date': chrono
                                                  .productionDateFormatted,
                                            }),
                                            style: TextStyle(
                                              color: context.textMutedColor,
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (chrono.isOfflineGenerated)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.idleAmber
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'OFFLINE',
                                                style: TextStyle(
                                                  color: AppColors.idleAmber,
                                                  fontSize: 8.5,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 3,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 11,
                                                color: context
                                                    .textSecondaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                context.trArgs(
                                                    'time_label', {
                                                  'time': chrono
                                                      .plantTimeOnlyFormatted,
                                                }),
                                                style: TextStyle(
                                                  color: context
                                                      .textSecondaryColor,
                                                  fontSize: 10.5,
                                                  fontFamily: 'monospace',
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.public_rounded,
                                                size: 10,
                                                color:
                                                    context.textMutedColor,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'UTC: ${chrono.utcTimeOnlyFormatted}',
                                                style: TextStyle(
                                                  color:
                                                      context.textMutedColor,
                                                  fontSize: 10,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
