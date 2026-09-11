import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/energya_logo.dart';
import '../../../../auth/domain/enums/user_role.dart';
import '../../../../auth/presentation/screens/settings_screen.dart';
import '../../../../auth/presentation/widgets/persona_indicator_chip.dart';
import '../../../../auth/presentation/widgets/role_guard.dart';
import '../../../../work_orders/presentation/screens/create_repair_request_screen.dart';
import '../../../../work_orders/presentation/screens/work_orders_list_screen.dart';
import '../../screens/qr_machine_scanner_screen.dart';

/// Top header bar with logo, persona switcher, settings, WO shortcuts, and QR scanner.
class PlantOverviewHeaderBar extends StatelessWidget {
  const PlantOverviewHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 10,
        children: [
          const EnergyaLogo(height: 22, showContainer: true),
          const PersonaIndicatorChip(compact: true),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                tooltip: context.tr('settings_title'),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.settings_rounded,
                  color: context.textSecondaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                tooltip: context.tr('tab_work_orders'),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WorkOrdersListScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.build_circle_rounded,
                  color: context.brandPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              RoleGuard(
                allowedRoles: const [
                  UserRole.operator,
                  UserRole.maintenanceSupervisor,
                ],
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateRepairRequestScreen(),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: context.tr('repair_request_btn'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.energyaAccentOrange
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.energyaAccentOrange
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: AppColors.energyaAccentOrange,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                tooltip: context.tr('qr_scanner_title'),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const QrMachineScannerScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: context.brandPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
