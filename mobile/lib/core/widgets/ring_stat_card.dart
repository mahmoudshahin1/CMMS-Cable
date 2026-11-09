import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// KPI card showing a value inside a circular progress ring instead of a
/// flat number row. [progress] is 0.0-1.0; pass null for an indeterminate
/// (near-full, muted) ring when there's no meaningful fraction to show.
class RingStatCard extends StatelessWidget {
  final String label;
  final String centerValue;
  final String? footnote;
  final double? progress;
  final Color color;

  const RingStatCard({
    super.key,
    required this.label,
    required this.centerValue,
    this.footnote,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = (progress ?? 0.82).clamp(0.0, 1.0);

    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: context.isDarkMode ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(54, 54),
                  painter: RingProgressPainter(
                    progress: clamped,
                    trackColor: context.borderColor,
                    valueColor: color,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerValue,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 1),
            Text(
              footnote!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RingProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color valueColor;

  RingProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 5) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, trackPaint);

    final valuePaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5707963267948966; // -90deg, top of circle
    final sweepAngle = progress * 2 * 3.141592653589793;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.valueColor != valueColor;
}
