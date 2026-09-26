import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextThemeFactory {
  static TextTheme buildTextTheme({
    required Brightness brightness,
    required Locale locale,
    required Color textColor,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final fontTheme = locale.languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(baseTextTheme)
        : GoogleFonts.interTextTheme(baseTextTheme);

    return fontTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }
}
