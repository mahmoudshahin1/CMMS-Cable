import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/service_locator.dart';
import 'core/localization/locale_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/main_navigation_shell.dart';
import 'features/assets/presentation/cubit/machine_cubit.dart';
import 'features/downtime/presentation/cubit/downtime_cubit.dart';
import 'features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'features/analytics/presentation/cubit/analytics_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

/// Root application widget.
///
/// Sets up the global [MultiBlocProvider] tree, locale switching,
/// theme switching, and the [MainNavigationShell] as the home page.
class CableCmmsApp extends StatelessWidget {
  const CableCmmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
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
                home: const MainNavigationShell(),
              );
            },
          );
        },
      ),
    );
  }
}
