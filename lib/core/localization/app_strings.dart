import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_cubit.dart';
import 'dictionaries/en_strings.dart';
import 'dictionaries/ar_strings.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': enStrings,
    'ar': arStrings,
  };

  static String get(String key, String langCode) {
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

extension AppStringsExtension on BuildContext {
  String tr(String key) {
    String langCode = 'en';
    try {
      langCode = read<LocaleCubit>().state.languageCode;
    } catch (_) {
      langCode = Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';
    }
    return AppStrings.get(key, langCode);
  }

  /// Translate with placeholder replacement: {key} → value
  String trArgs(String key, Map<String, String> args) {
    String result = tr(key);
    args.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }

  /// Read-only locale check (safe in callbacks and build methods alike)
  String trRead(String key) => tr(key);

  bool get isArabic {
    String langCode = 'en';
    try {
      langCode = read<LocaleCubit>().state.languageCode;
    } catch (_) {
      langCode = Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';
    }
    return langCode == 'ar';
  }
}
