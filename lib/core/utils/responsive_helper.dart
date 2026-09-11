import 'package:flutter/material.dart';

/// Central responsive design utilities for the Energya CMMS app.
///
/// Breakpoints:
/// - Compact Mobile: < 360px
/// - Mobile: 360–599px
/// - Tablet: 600–849px
/// - Desktop: ≥ 850px (sidebar layout already handled in main.dart)
class ResponsiveHelper {
  static const double compactMobileBreakpoint = 360;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 850;

  static bool isCompactMobile(double width) => width < compactMobileBreakpoint;
  static bool isMobile(double width) =>
      width >= compactMobileBreakpoint && width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isDesktop(double width) => width >= tabletBreakpoint;

  /// Returns the optimal number of grid columns for the given width.
  static int gridColumnCount(double width) {
    if (width < 360) return 1;
    if (width < 600) return 2;
    if (width < 850) return 3;
    return 4;
  }

  /// Returns the optimal child aspect ratio for machine cards at the given width.
  static double machineCardAspectRatio(double width) {
    if (width < 360) return 0.80;
    if (width < 600) return 0.70;
    if (width < 850) return 0.75;
    return 0.80;
  }

  /// Returns symmetric horizontal padding appropriate for the screen width.
  static double horizontalPadding(double width) {
    if (width < 360) return 8;
    if (width < 600) return 16;
    if (width < 850) return 20;
    return 24;
  }
}

/// Convenience extension on [BuildContext] for responsive checks.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isCompactMobile =>
      ResponsiveHelper.isCompactMobile(screenWidth);
  bool get isResponsiveMobile => ResponsiveHelper.isMobile(screenWidth);
  bool get isResponsiveTablet => ResponsiveHelper.isTablet(screenWidth);
  bool get isResponsiveDesktop => ResponsiveHelper.isDesktop(screenWidth);

  int get gridColumns => ResponsiveHelper.gridColumnCount(screenWidth);
  double get machineAspectRatio =>
      ResponsiveHelper.machineCardAspectRatio(screenWidth);
  double get responsivePadding =>
      ResponsiveHelper.horizontalPadding(screenWidth);
}
