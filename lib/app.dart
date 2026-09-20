import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/service_locator.dart';
import 'core/localization/locale_cubit.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/navigation/main_navigation_shell.dart';

import 'features/assets/presentation/cubit/machine_cubit.dart';
import 'features/downtime/presentation/cubit/downtime_cubit.dart';
import 'features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'features/analytics/presentation/cubit/analytics_cubit.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';

/// Global navigator key allowing screens/dialogs to pop back to root on logout.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Root application widget.
///
/// Sets up the global [MultiBlocProvider] tree, locale switching,
/// theme switching, and an [_AuthGate] that routes between
/// [LoginScreen] and [MainNavigationShell] based on auth state.
class CableCmmsApp extends StatelessWidget {
  const CableCmmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(getIt<AuthRepository>()),
        ),
        BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<MachineCubit>(
          create: (_) => getIt<MachineCubit>()..loadMachines(),
        ),
        BlocProvider<DowntimeCubit>(
          create: (_) => getIt<DowntimeCubit>()..loadDowntimeLogs(),
        ),
        BlocProvider<WorkOrderCubit>(
          create: (_) => getIt<WorkOrderCubit>()..loadWorkOrders(),
        ),
        BlocProvider<AnalyticsCubit>(
          create: (context) => AnalyticsCubit(
            machineCubit: context.read<MachineCubit>(),
            downtimeCubit: context.read<DowntimeCubit>(),
            workOrderCubit: context.read<WorkOrderCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                navigatorKey: appNavigatorKey,
                title: 'Cable Manufacturing CMMS',
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: AppTheme.getLightTheme(
                  locale: locale,
                  primaryColor: themeState.primaryColor,
                  secondaryColor: themeState.secondaryColor,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  locale: locale,
                  primaryColor: themeState.primaryColor,
                  secondaryColor: themeState.secondaryColor,
                ),
                themeMode: themeState.themeMode,
                home: const _AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Routes between [LoginScreen] and [MainNavigationShell] based on
/// the current [AuthState].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous is Authenticated && current is! Authenticated,
      listener: (context, state) {
        // Pop all pushed routes (SettingsScreen, dialogs, etc.) so user
        // lands directly on the LoginScreen root.
        appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      },
      buildWhen: (previous, current) {
        // Rebuild only when entering or leaving Authenticated state,
        // or transitioning away from initial startup.
        // Keeps LoginScreen mounted during AuthLoading and AuthError.
        if (current is Authenticated || previous is Authenticated) {
          return true;
        }
        if (previous is AuthInitial) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavigationShell();
        }

        if (state is AuthInitial) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.electricBlue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('checking_session'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // AuthLoading, AuthError, and Unauthenticated all remain on LoginScreen
        return const LoginScreen();
      },
    );
  }
}
