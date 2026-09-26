import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder dashboard for TECHNICIAN (maintenanceTech) role.
///
/// Displays the technician's specialty (ELECTRICAL / MECHANICAL) as a
/// prominent badge to confirm role-based redirection is working.
class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;
        final specialty = user?.speciality ?? 'غير محدد';

        // Color based on specialty
        final isElectrical =
            specialty.toUpperCase().contains('ELECTRICAL') ||
                specialty.contains('كهرباء');
        final specialtyColor = isElectrical
            ? AppColors.idleAmber
            : AppColors.cyberCyan;
        final specialtyIcon = isElectrical
            ? Icons.electrical_services_rounded
            : Icons.build_rounded;

        return Scaffold(
          backgroundColor: AppColors.darkNavy,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Specialty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            specialtyColor,
                            specialtyColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: specialtyColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            specialtyIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            specialty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Icon(
                      Icons.handyman_rounded,
                      size: 64,
                      color: specialtyColor,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لوحة تحكم الفني',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً ${user?.name ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Specialty info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slateCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: specialtyColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(specialtyIcon, color: specialtyColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'التخصص: $specialty',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: specialtyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSignOutButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.read<AuthCubit>().signOut(),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text(
        'تسجيل الخروج',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.downMaintenanceRed,
        side: BorderSide(
          color: AppColors.downMaintenanceRed.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
