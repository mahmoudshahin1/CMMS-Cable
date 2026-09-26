import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Bottom sheet panel providing manual code text field and quick factory preset machine tags.
class ScannerManualLookupPanel extends StatelessWidget {
  final TextEditingController manualInputController;
  final bool isProcessingCode;
  final ValueChanged<String> onCodeSubmitted;

  const ScannerManualLookupPanel({
    super.key,
    required this.manualInputController,
    required this.isProcessingCode,
    required this.onCodeSubmitted,
  });

  Widget _buildQuickCodeChip(
    BuildContext context,
    String code,
    String name,
  ) {
    final label = '$code ($name)';
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: context.isDarkMode
            ? AppColors.darkNavy
            : const Color(0xFFE2E8F0),
        side: BorderSide(color: context.borderColor),
        labelStyle: TextStyle(
          color: context.textPrimaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        onPressed: () => onCodeSubmitted(code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('manual_code_lookup_title'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isProcessingCode) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: manualInputController,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: context.tr('manual_code_hint'),
                        hintStyle: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 12,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: context.isDarkMode
                            ? AppColors.darkNavy
                            : AppColors.lightBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                      ),
                      onSubmitted: onCodeSubmitted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        onCodeSubmitted(manualInputController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text(
                      context.tr('search_code_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickCodeChip(
                    context,
                    'EXT-01',
                    context.tr('chip_ext01'),
                  ),
                  _buildQuickCodeChip(
                    context,
                    'DR01',
                    context.tr('chip_dr01'),
                  ),
                  _buildQuickCodeChip(
                    context,
                    'RS01',
                    context.tr('chip_rs01'),
                  ),
                  _buildQuickCodeChip(
                    context,
                    'EXT-02',
                    context.tr('chip_ext02'),
                  ),
                  _buildQuickCodeChip(
                    context,
                    'ARM-01',
                    context.tr('chip_arm01'),
                  ),
                  _buildQuickCodeChip(
                    context,
                    'TB01',
                    context.tr('chip_tb01'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
