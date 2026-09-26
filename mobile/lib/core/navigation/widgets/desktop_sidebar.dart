import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/auth/domain/models/user_model.dart';
import 'sidebar_header.dart';
import 'sidebar_nav_list.dart';
import 'sidebar_footer.dart';

/// Industrial Energya Cables desktop sidebar with navigation, branding,
/// and user profile footer. Designed for wide-screen layouts (≥850px).
class DesktopSidebar extends StatelessWidget {
  final List<({IconData icon, String label})> sidebarItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final UserModel? currentUser;
  final UserRole currentRole;

  const DesktopSidebar({
    super.key,
    required this.sidebarItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.currentUser,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.energyaDeepNavy,
            AppColors.energyaSecondaryDeepBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: SidebarNavList(
              items: sidebarItems,
              selectedIndex: selectedIndex,
              onItemSelected: onItemSelected,
            ),
          ),
          SidebarFooter(
            currentUser: currentUser,
            currentRole: currentRole,
          ),
        ],
      ),
    );
  }
}
