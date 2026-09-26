import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../database/hive_boxes.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _localeKey = 'selected_language_code';

  LocaleCubit() : super(const Locale('ar')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settingsBox)) {
        final box = Hive.box(HiveBoxes.settingsBox);
        final code = box.get(_localeKey, defaultValue: 'ar') as String;
        emit(Locale(code));
      }
    } catch (_) {
      emit(const Locale('ar'));
    }
  }

  void toggleLanguage() {
    final nextCode = state.languageCode == 'ar' ? 'en' : 'ar';
    final nextLocale = Locale(nextCode);
    emit(nextLocale);
    _saveLocale(nextCode);
  }

  void toggleLocale() => toggleLanguage();

  void setLocale(Locale locale) {
    emit(locale);
    _saveLocale(locale.languageCode);
  }

  void _saveLocale(String languageCode) {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settingsBox)) {
        final box = Hive.box(HiveBoxes.settingsBox);
        box.put(_localeKey, languageCode);
      }
    } catch (_) {}
  }

  bool get isArabic => state.languageCode == 'ar';
}
