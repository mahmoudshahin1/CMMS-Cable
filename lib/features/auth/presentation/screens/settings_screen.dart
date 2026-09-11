import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_strings.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/settings/accent_palette_section.dart';
import '../widgets/settings/language_selector_section.dart';
import '../widgets/settings/system_info_card.dart';
import '../widgets/settings/theme_appearance_section.dart';
import '../widgets/settings/user_permissions_card.dart';
import '../widgets/settings/user_profile_card.dart';

/// Settings screen for cable plant users, providing appearance, accent colors,
/// language customization, and user permission overview.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is Authenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('settings_title')),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (currentUser != null) ...[
                UserProfileCard(user: currentUser),
                const SizedBox(height: 16),
                UserPermissionsCard(user: currentUser),
                const SizedBox(height: 20),
              ],
              const ThemeAppearanceSection(),
              const SizedBox(height: 20),
              const AccentPaletteSection(),
              const SizedBox(height: 20),
              const LanguageSelectorSection(),
              const SizedBox(height: 20),
              const SystemInfoCard(),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}