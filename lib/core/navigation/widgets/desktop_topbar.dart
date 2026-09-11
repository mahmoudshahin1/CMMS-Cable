import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../localization/app_strings.dart';
import '../../../features/work_orders/presentation/screens/create_repair_request_screen.dart';

/// Desktop top bar with breadcrumb navigation and quick-action buttons.
/// Displayed above the main content area on wide-screen layouts (≥850px).
class DesktopTopbar extends StatelessWidget {
  final String currentPageLabel;

  const DesktopTopbar({
    super.key,
    required this.currentPageLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.darkNavy : Colors.white,
        border: Border(
          bottom: BorderSide(color: context.borderColor),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Energya Cables  /  ',
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: Text(
                    currentPageLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateRepairRequestScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.energyaAccentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
            ),
            icon: const Icon(Icons.add_task_rounded, size: 16),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.tr('repair_request_btn'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
