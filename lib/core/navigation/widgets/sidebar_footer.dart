import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app.dart';
import '../../theme/app_colors.dart';
import '../../localization/app_strings.dart';
import '../../localization/locale_cubit.dart';
import '../../theme/theme_cubit.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../features/auth/presentation/screens/settings_screen.dart';

class SidebarFooter extends StatelessWidget {
  final UserModel? currentUser;
  final UserRole currentRole;

  const SidebarFooter({
    super.key,
    required this.currentUser,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.energyaDeepNavy,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // User Info (display only — persona switching removed)
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    currentRole.roleColor.withValues(alpha: 0.25),
                child: Icon(
                  currentRole.icon,
                  color: currentRole.roleColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.name ?? context.tr('shift_manager'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentRole.badgeTitle,
                      style: TextStyle(
                        color: currentRole.roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.language_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('lang_toggle'),
                onPressed: () =>
                    context.read<LocaleCubit>().toggleLanguage(),
              ),
              IconButton(
                icon: Icon(
                  context.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('theme_toggle'),
                onPressed: () =>
                    context.read<ThemeCubit>().toggleTheme(),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                tooltip: context.tr('settings_title'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                tooltip: 'تسجيل الخروج',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final authCubit = context.read<AuthCubit>();
                    appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
                    await authCubit.signOut();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
