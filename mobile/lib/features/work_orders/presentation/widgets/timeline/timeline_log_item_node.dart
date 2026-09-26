import 'package:flutter/material.dart';
import 'timeline_step_helper.dart';

/// Circular node icon displayed on the vertical timeline axis.
class TimelineLogItemNode extends StatelessWidget {
  final String stepName;

  const TimelineLogItemNode({
    super.key,
    required this.stepName,
  });

  @override
  Widget build(BuildContext context) {
    final stepColor = TimelineStepHelper.getStepColor(stepName);
    final icon = TimelineStepHelper.getStepIcon(stepName);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: stepColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: stepColor, width: 2),
      ),
      child: Icon(
        icon,
        color: stepColor,
        size: 18,
      ),
    );
  }
}
