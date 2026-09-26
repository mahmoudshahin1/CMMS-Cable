import 'package:flutter/material.dart';

class EnergyaLogo extends StatelessWidget {
  final double height;
  final double? width;
  final BoxFit fit;
  final bool showContainer;

  const EnergyaLogo({
    super.key,
    this.height = 36,
    this.width,
    this.fit = BoxFit.contain,
    this.showContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.asset(
      'assets/images/logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'https://energyacables.com/themes/cyan/assets/images/logo.png',
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, err, stack) {
            // High-fidelity fallback brand
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C4595),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'energya',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF04E37),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CABLES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (showContainer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
