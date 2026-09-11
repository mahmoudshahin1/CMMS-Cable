import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'theme_state.dart';
import 'accent_palette.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'is_dark_mode';
  static const String _paletteKey = 'accent_palette_id';

  ThemeCubit() : super(const ThemeState()) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final isDark = box.get(_themeKey, defaultValue: true) as bool;
        final paletteId =
            box.get(_paletteKey, defaultValue: AppPalettes.cyberElectric.id)
                as String;
        final palette = AppPalettes.findById(paletteId);

        emit(ThemeState(
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          accentPalette: palette,
        ));
      }
    } catch (_) {
      emit(const ThemeState());
    }
  }

  void toggleTheme() {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: newMode));
    _saveTheme(newMode == ThemeMode.dark);
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
    _saveTheme(mode == ThemeMode.dark);
  }

  void setAccentPalette(AccentPalette palette) {
    emit(state.copyWith(accentPalette: palette));
    _savePalette(palette.id);
  }

  void _saveTheme(bool isDark) {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        box.put(_themeKey, isDark);
      }
    } catch (_) {}
  }

  void _savePalette(String paletteId) {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        box.put(_paletteKey, paletteId);
      }
    } catch (_) {}
  }
}
