import 'package:flutter/material.dart';

/// A small glowing dot used next to status labels (headers, machine cards)
/// as a compact live-status indicator, distinct from [StatusBadge]'s full
/// pill. Set [animate] to false for a static dot (e.g. idle/offline states).
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const PulseDot({
    super.key,
    required this.color,
    this.size = 7,
    this.animate = true,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 0.35 + (_controller.value * 0.65);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * glow),
                blurRadius: widget.size * 1.4 * glow,
                spreadRadius: widget.size * 0.25 * glow,
              ),
            ],
          ),
        );
      },
    );
  }
}
