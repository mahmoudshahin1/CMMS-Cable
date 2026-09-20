import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:orning_and_evening_remembrances/core/theme/app_colors.dart';
import 'package:orning_and_evening_remembrances/core/localization/app_strings.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_state.dart';
import 'login_form_fields.dart';

/// Form card container for email/password authentication inputs and submission.
class LoginFormCard extends StatefulWidget {
  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSignIn;

  const LoginFormCard({
    super.key,
    required this.isDark,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
  });

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slateCard.withValues(alpha: 0.9)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.slateBorder.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF0C4595).withValues(alpha: 0.08),
            blurRadius: 36,
            spreadRadius: isDark ? 4 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              context.tr('login_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('login_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                color: isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),

            // Error banner
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthError) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.downMaintenanceRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.downMaintenanceRed.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.downMaintenanceRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.downMaintenanceRed,
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Email field
            LoginFormLabel(text: context.tr('login_email_label'), isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
              ),
              decoration: LoginFormInputDecoration.build(
                hint: context.tr('login_email_hint'),
                prefixIcon: Icons.email_outlined,
                isDark: isDark,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('login_email_required');
                }
                final trimmed = value.trim();
                if (!trimmed.contains('@') || !trimmed.contains('.')) {
                  return context.tr('login_email_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Password field
            LoginFormLabel(text: context.tr('login_password_label'), isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => widget.onSignIn(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
              ),
              decoration: LoginFormInputDecoration.build(
                hint: context.tr('login_password_hint'),
                prefixIcon: Icons.lock_outline_rounded,
                isDark: isDark,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isDark
                        ? AppColors.textMuted
                        : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('login_password_required');
                }
                if (value.length < 4) {
                  return context.tr('login_password_too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Login button
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return FilledButton(
                  onPressed: isLoading ? null : widget.onSignIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.electricBlue,
                    disabledBackgroundColor:
                        AppColors.electricBlue.withValues(alpha: 0.5),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          context.tr('login_btn'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
