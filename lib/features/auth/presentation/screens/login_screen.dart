import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/app_strings.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login/login_background.dart';
import '../widgets/login/login_header_logo.dart';
import '../widgets/login/login_form_card.dart';
import '../widgets/login/login_quick_access.dart';
import '../widgets/login/login_top_bar.dart';

/// Industrial authentication screen for Cable Ops CMMS.
///
/// Coordinates animations, credentials validation, theme & language switching,
/// and delegates UI rendering to modular sub-widgets under 200 lines each.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    final rawEmail = _emailController.text.trim();
    if (rawEmail.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    if (!rawEmail.contains('@') && !rawEmail.contains(' ')) {
      _emailController.text = '$rawEmail@cable.com';
    }
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      context.read<AuthCubit>().signIn(email: email, password: password);
    }
  }

  void _onSelectQuickAccount(String email, String labelKey) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = '123456';
    });
    final label = context.tr(labelKey);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.trArgs('login_quick_autofilled', {'label': label}),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.electricBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    final isDark = context.isDarkMode;
    final isArabic = context.isArabic;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.downMaintenanceRed,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkNavy : const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // Ambient animated background
            LoginBackground(isDark: isDark),

            // Main scrollable content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.3 : 24,
                    vertical: 36,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          LoginHeaderLogo(isDark: isDark),
                          const SizedBox(height: 30),
                          LoginFormCard(
                            isDark: isDark,
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onSignIn: _onSignIn,
                          ),
                          const SizedBox(height: 28),
                          LoginQuickAccessPanel(
                            isDark: isDark,
                            onSelectAccount: _onSelectQuickAccount,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.tr('login_footer'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              color: isDark
                                  ? AppColors.textMuted.withValues(alpha: 0.5)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top action bar (Language & Theme toggles)
            LoginTopBar(
              isDark: isDark,
              isArabic: isArabic,
              onToggleLanguage: () =>
                  context.read<LocaleCubit>().toggleLanguage(),
              onToggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}
