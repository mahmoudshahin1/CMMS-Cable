import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Fallback placeholder when camera hardware is unavailable (desktop, web, emulator).
class ScannerNoCameraFallback extends StatelessWidget {
  const ScannerNoCameraFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.slateCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 56,
                color: AppColors.cyberCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('industrial_scanner_ready'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('scanner_instruction'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
