import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Industrial viewfinder reticle with 4 corner brackets and animated laser sweep.
class ScannerReticleOverlay extends StatelessWidget {
  final AnimationController laserController;

  const ScannerReticleOverlay({
    super.key,
    required this.laserController,
  });

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const double size = 26.0;
    const double thickness = 3.5;
    const color = AppColors.cyberCyan;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: _buildCorner(isTop: true, isLeft: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _buildCorner(isTop: true, isLeft: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _buildCorner(isTop: false, isLeft: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildCorner(isTop: false, isLeft: false),
              ),

              // Animated Laser Sweep Line
              AnimatedBuilder(
                animation: laserController,
                builder: (context, child) {
                  return Positioned(
                    top: 10 + (240 * laserController.value),
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.cyberCyan,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyberCyan.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Subtitle instruction
              Positioned(
                bottom: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('point_camera_at_barcode'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
