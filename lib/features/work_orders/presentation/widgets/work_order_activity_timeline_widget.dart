import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/work_order_activity_log.dart';
import '../../domain/models/work_order_model.dart';
import 'timeline/cross_shift_breakdown_banner.dart';
import 'timeline/timeline_header_bar.dart';
import 'timeline/timeline_log_content_box.dart';
import 'timeline/timeline_log_item_node.dart';

/// Industrial certified, tamper-proof activity audit trail timeline widget.
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
  bool _ascending = false; // default newest first for fast operational field access

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
          // Header & Audit Seal with Sort Toggle
          TimelineHeaderBar(
            ascending: _ascending,
            onToggleSort: () => setState(() => _ascending = !_ascending),
          ),
          Divider(height: 1, color: context.borderColor),

          // Cross-Shift Warning & OEE Breakdown Banner
          CrossShiftBreakdownBanner(
            workOrder: widget.workOrder,
            activityLogs: widget.activityLogs,
          ),

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

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TimelineLogItemNode(stepName: log.stepName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TimelineLogContentBox(log: log),
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
