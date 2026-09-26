import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'accent_palette.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final AccentPalette accentPalette;

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.accentPalette = AppPalettes.cyberElectric,
  });

  bool get isDark => themeMode == ThemeMode.dark;

  Color get primaryColor => accentPalette.primary;
  Color get secondaryColor => accentPalette.secondary;

  ThemeState copyWith({
    ThemeMode? themeMode,
    AccentPalette? accentPalette,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentPalette: accentPalette ?? this.accentPalette,
    );
  }

  @override
  List<Object?> get props => [themeMode, accentPalette];
}
