import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SwipeActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onSwipeCompleted;
  final Color backgroundColor;
  final IconData icon;

  const SwipeActionButton({
    super.key,
    required this.label,
    required this.onSwipeCompleted,
    this.backgroundColor = AppColors.downMaintenanceRed,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 56.0;

        return Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? AppColors.darkNavy
                : AppColors.energyaLightSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: widget.backgroundColor.withValues(alpha: 0.5)),
          ),
          child: Stack(
            children: [
              // Background filled container
              Container(
                width: _dragPosition + 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Center Text
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isCompleted ? 'CONFIRMED!' : widget.label.toUpperCase(),
                      style: TextStyle(
                        color: context.isDarkMode
                            ? AppColors.textPrimary
                            : AppColors.energyaTextPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              // Draggable Knob
              Positioned(
                left: _dragPosition,
                top: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;
                    if (_dragPosition >= maxDrag * 0.8) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isCompleted = true;
                      });
                      widget.onSwipeCompleted();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.backgroundColor.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check_rounded : widget.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
