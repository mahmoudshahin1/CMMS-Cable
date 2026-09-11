import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/mock_users.dart';
import '../../domain/enums/user_role.dart';
import '../screens/settings_screen.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';

class SwitchPersonaBottomSheet extends StatelessWidget {
  const SwitchPersonaBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SwitchPersonaBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.borderColor, width: 1.5),
          left: BorderSide(color: context.borderColor, width: 1.5),
          right: BorderSide(color: context.borderColor, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20, left: 16, right: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.switch_account_rounded,
                    color: context.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('switch_persona_title'),
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        context.tr('switch_persona_sub'),
                        style: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: context.textMutedColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable list of mock personas
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final currentUserId =
                        state is Authenticated ? state.user.id : '';

                    Widget buildUserCard(UserModel user) {
                      final isSelected = user.id == currentUserId;
                      final role = user.role;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? role.roleColor.withValues(alpha: 0.12)
                              : (context.isDarkMode
                                  ? AppColors.slateCard
                                  : AppColors.energyaLightSurface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? role.roleColor
                                : context.borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                role.roleColor.withValues(alpha: 0.2),
                            child: Icon(role.icon,
                                color: role.roleColor, size: 20),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (context.isDarkMode
                                            ? Colors.white
                                            : role.roleColor)
                                        : context.textPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: role.roleColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role.badgeTitle,
                                  style: TextStyle(
                                    color: role.roleColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${user.email} • ${user.department != null ? user.department!.name.toUpperCase() : (user.speciality ?? 'Plant-wide')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded,
                                  color: role.roleColor, size: 22)
                              : Icon(Icons.circle_outlined,
                                  color: context.textMutedColor, size: 20),
                          onTap: () {
                            context.read<AuthCubit>().switchUser(user);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    context.trRead('switched_to_user').replaceAll('{name}', user.name).replaceAll('{detail}', user.department != null ? user.department!.name : role.badgeTitle)),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.cardBg,
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Department Users Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.factory_rounded,
                                  color: context.isDarkMode
                                      ? AppColors.cyberCyan
                                      : context.brandPrimary,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('dept_users_header'),
                                style: TextStyle(
                                  color: context.isDarkMode
                                      ? AppColors.cyberCyan
                                      : context.brandPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...MockUsers.departmentUsers.map(buildUserCard),

                        const SizedBox(height: 12),

                        // 2. Plant Wide & Field Techs Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded,
                                  color: context.brandPrimary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('plant_wide_header'),
                                style: TextStyle(
                                  color: context.brandPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...MockUsers.plantWideUsers.map(buildUserCard),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textPrimaryColor,
                  side: BorderSide(color: context.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                label: Text(
                  context.tr('open_settings_btn'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
