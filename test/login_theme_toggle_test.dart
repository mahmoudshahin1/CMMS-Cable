import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orning_and_evening_remembrances/core/theme/theme_cubit.dart';
import 'package:orning_and_evening_remembrances/core/theme/theme_state.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_theme.dart';
import 'package:orning_and_evening_remembrances/core/localization/locale_cubit.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/screens/login_screen.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/repositories/auth_repository.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';

class MockAuthRepo implements AuthRepository {
  @override
  UserModel? get cachedUser => null;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> getUserProfile(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<UserModel>> getUsersByRole(
    String role, {
    String? speciality,
  }) async => [];
}

void main() {
  testWidgets('LoginScreen toggles between dark and light themes smoothly', (tester) async {
    final themeCubit = ThemeCubit();
    final localeCubit = LocaleCubit();
    final authCubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<LocaleCubit>.value(value: localeCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              theme: AppTheme.getLightTheme(),
              darkTheme: AppTheme.getDarkTheme(),
              themeMode: themeState.themeMode,
              home: const LoginScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially dark mode: Theme icon should be light_mode_rounded (suggesting switch to light)
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);

    // Tap the theme toggle button
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    // Now in light mode: Theme icon should be dark_mode_rounded (suggesting switch to dark)
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_rounded), findsNothing);

    // Tap again to switch back
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    // Back to dark mode
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);
  });

  testWidgets('LoginScreen toggles between Arabic and English dynamically', (tester) async {
    final themeCubit = ThemeCubit();
    final localeCubit = LocaleCubit();
    final authCubit = AuthCubit(MockAuthRepo());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<LocaleCubit>.value(value: localeCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp(
                  locale: locale,
                  supportedLocales: const [Locale('ar'), Locale('en')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: AppTheme.getLightTheme(locale: locale),
                  darkTheme: AppTheme.getDarkTheme(locale: locale),
                  themeMode: themeState.themeMode,
                  home: const LoginScreen(),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initially Arabic:
    expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('English'), findsOneWidget); // Language button shows 'English'

    // 2. Tap language button to switch to English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 3. Now English:
    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('عربي'), findsOneWidget); // Language button shows 'عربي'

    // 4. Tap 'عربي' to switch back to Arabic
    await tester.tap(find.text('عربي'));
    await tester.pumpAndSettle();

    // 5. Back to Arabic:
    expect(find.text('تسجيل الدخول'), findsAtLeastNWidgets(1));
    expect(find.text('English'), findsOneWidget);
  });
}
