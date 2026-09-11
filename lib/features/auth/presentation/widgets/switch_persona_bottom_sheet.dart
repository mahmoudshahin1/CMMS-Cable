import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/mock_users.dart';
import '../../domain/models/user_model.dart';
import '../../domain/enums/user_role.dart';
import '../screens/settings_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import 'persona/persona_user_card.dart';
import 'persona/persona_group_header.dart';

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

  void _onSelectUser(BuildContext context, UserModel user) {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final role = user.role;
    final message = context
        .trRead('switched_to_user')
        .replaceAll('{name}', user.name)
        .replaceAll(
            '{detail}',
            user.department != null
                ? user.department!.name
                : role.badgeTitle);
    final cardBg = context.cardBg;

    context.read<AuthCubit>().switchUser(user);
    nav.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardBg,
      ),
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
            _buildHeader(context),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final currentUserId =
                        state is Authenticated ? state.user.id : '';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PersonaGroupHeader(
                          icon: Icons.factory_rounded,
                          title: context.tr('dept_users_header'),
                          color: context.isDarkMode
                              ? AppColors.cyberCyan
                              : context.brandPrimary,
                        ),
                        ...MockUsers.departmentUsers.map((user) =>
                            PersonaUserCard(
                              user: user,
                              isSelected: user.id == currentUserId,
                              onTap: () => _onSelectUser(context, user),
                            )),
                        const SizedBox(height: 12),
                        PersonaGroupHeader(
                          icon: Icons.admin_panel_settings_rounded,
                          title: context.tr('plant_wide_header'),
                          color: context.brandPrimary,
                        ),
                        ...MockUsers.plantWideUsers.map((user) =>
                            PersonaUserCard(
                              user: user,
                              isSelected: user.id == currentUserId,
                              onTap: () => _onSelectUser(context, user),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return SizedBox(
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
    );
  }
}
