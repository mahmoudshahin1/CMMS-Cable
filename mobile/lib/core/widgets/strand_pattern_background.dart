import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Thin multi-wave line motif ("Current & Strand" visual language), loosely
/// evoking twisted cable strands. Intended ONLY as a low-opacity decorative
/// layer behind gradient headers -- never behind body content or text that
/// needs full contrast.
class StrandPatternBackground extends StatelessWidget {
  final List<Color> strandColors;
  final double opacity;

  const StrandPatternBackground({
    super.key,
    required this.strandColors,
    this.opacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _StrandPainter(colors: strandColors),
        ),
      ),
    );
  }
}

class _StrandPainter extends CustomPainter {
  final List<Color> colors;

  _StrandPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final waveSpecs = [
      (yFactor: 0.25, amplitude: 14.0, strokeWidth: 2.5, freq: 1.4, phase: 0.0),
      (yFactor: 0.5, amplitude: 20.0, strokeWidth: 2.0, freq: 1.1, phase: 0.8),
      (yFactor: 0.78, amplitude: 16.0, strokeWidth: 1.5, freq: 1.7, phase: 1.6),
    ];

    for (var i = 0; i < waveSpecs.length; i++) {
      final spec = waveSpecs[i];
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.strokeWidth
        ..strokeCap = StrokeCap.round;

      final baseY = size.height * spec.yFactor;
      final path = Path();
      const step = 6.0;
      for (double x = 0; x <= size.width; x += step) {
        final y = baseY +
            spec.amplitude *
                math.sin((x / size.width) * math.pi * spec.freq * 2 + spec.phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrandPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
