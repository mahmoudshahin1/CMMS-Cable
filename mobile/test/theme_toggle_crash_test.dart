import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme symmetry and button theme interpolation (prevent inherit mismatch crash)', () async {
    final completer = Completer<void>();

    runZonedGuarded(() {
      for (final lang in ['ar', 'en']) {
        final light = AppTheme.getLightTheme(locale: Locale(lang));
        final dark = AppTheme.getDarkTheme(locale: Locale(lang));

        // 1. Verify button themes are present in both
        expect(light.elevatedButtonTheme.style, isNotNull);
        expect(dark.elevatedButtonTheme.style, isNotNull);
        expect(light.outlinedButtonTheme.style, isNotNull);
        expect(dark.outlinedButtonTheme.style, isNotNull);
        expect(light.textButtonTheme.style, isNotNull);
        expect(dark.textButtonTheme.style, isNotNull);
        expect(light.filledButtonTheme.style, isNotNull);
        expect(dark.filledButtonTheme.style, isNotNull);

        // 2. Verify inherit is false on both button text styles to prevent lerp crash
        final lightOutlinedTextStyle =
            light.outlinedButtonTheme.style?.textStyle?.resolve({});
        final darkOutlinedTextStyle =
            dark.outlinedButtonTheme.style?.textStyle?.resolve({});
        expect(lightOutlinedTextStyle?.inherit, isFalse);
        expect(darkOutlinedTextStyle?.inherit, isFalse);

        final lightElevatedTextStyle =
            light.elevatedButtonTheme.style?.textStyle?.resolve({});
        final darkElevatedTextStyle =
            dark.elevatedButtonTheme.style?.textStyle?.resolve({});
        expect(lightElevatedTextStyle?.inherit, isFalse);
        expect(darkElevatedTextStyle?.inherit, isFalse);

        // 3. Verify OutlinedButtonThemeData.lerp does NOT throw Failed to interpolate TextStyles
        for (double t = 0.0; t <= 1.0; t += 0.25) {
          final lerpedOutlined = OutlinedButtonThemeData.lerp(
            light.outlinedButtonTheme,
            dark.outlinedButtonTheme,
            t,
          );
          expect(lerpedOutlined, isNotNull);

          final lerpedElevated = ElevatedButtonThemeData.lerp(
            light.elevatedButtonTheme,
            dark.elevatedButtonTheme,
            t,
          );
          expect(lerpedElevated, isNotNull);

          final lerpedTheme = ThemeData.lerp(light, dark, t);
          expect(lerpedTheme, isNotNull);
        }
      }
      completer.complete();
    }, (error, stackTrace) {
      // In test sandbox without internet, google_fonts may trigger a network error in background.
      // If it's the inherit assertion error, fail the test immediately.
      if (error.toString().contains('Failed to interpolate TextStyles')) {
        completer.completeError(error, stackTrace);
      }
    });

    await completer.future;
  });
}
