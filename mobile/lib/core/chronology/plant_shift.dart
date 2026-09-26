// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../theme/app_colors.dart';

@HiveType(typeId: 14)
enum PlantShift {
  @HiveField(0)
  shift1_Morning,

  @HiveField(1)
  shift2_Evening,

  @HiveField(2)
  shift3_Night;

  // Aliases for compatibility
  static PlantShift get shift1 => shift1_Morning;
  static PlantShift get shift2 => shift2_Evening;
  static PlantShift get shift3 => shift3_Night;
  static PlantShift get shiftA => shift1_Morning;
  static PlantShift get shiftB => shift2_Evening;
  static PlantShift get shiftC => shift3_Night;
}

class ShiftAllocation {
  final PlantShift shift;
  final String shiftNameAr;
  final String shiftNameEn;
  final String productionDate;

  const ShiftAllocation({
    required this.shift,
    required this.shiftNameAr,
    required this.shiftNameEn,
    required this.productionDate,
  });

  static ShiftAllocation fromDateTime(DateTime localTime) {
    final hour = localTime.hour;
    final minute = localTime.minute;
    final timeInMinutes = hour * 60 + minute;

    // Shift 1 (Morning): 07:30 (450m) to 15:30 (930m)
    if (timeInMinutes >= 450 && timeInMinutes < 930) {
      return ShiftAllocation(
        shift: PlantShift.shift1_Morning,
        shiftNameAr: "الوردية الأولى (صباحية)",
        shiftNameEn: "Shift 1 (Morning)",
        productionDate: _formatDate(localTime),
      );
    }
    // Shift 2 (Evening): 15:30 (930m) to 23:00 (1380m)
    else if (timeInMinutes >= 930 && timeInMinutes < 1380) {
      return ShiftAllocation(
        shift: PlantShift.shift2_Evening,
        shiftNameAr: "الوردية الثانية (مسائية)",
        shiftNameEn: "Shift 2 (Evening)",
        productionDate: _formatDate(localTime),
      );
    }
    // Shift 3 (Night): 23:00 (1380m) to 07:30 (450m next morning)
    else {
      // If between 00:00 and 07:29, production date belongs to yesterday's night shift
      final prodDate = timeInMinutes < 450
          ? localTime.subtract(const Duration(days: 1))
          : localTime;
      return ShiftAllocation(
        shift: PlantShift.shift3_Night,
        shiftNameAr: "الوردية الثالثة (ليلية)",
        shiftNameEn: "Shift 3 (Night)",
        productionDate: _formatDate(prodDate),
      );
    }
  }

  static String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
}

extension PlantShiftExtension on PlantShift {
  String get code {
    switch (this) {
      case PlantShift.shift1_Morning:
        return 'SHIFT_1';
      case PlantShift.shift2_Evening:
        return 'SHIFT_2';
      case PlantShift.shift3_Night:
        return 'SHIFT_3';
    }
  }

  String get shortLabel {
    switch (this) {
      case PlantShift.shift1_Morning:
        return 'وردية 1';
      case PlantShift.shift2_Evening:
        return 'وردية 2';
      case PlantShift.shift3_Night:
        return 'وردية 3';
    }
  }

  String get shortLabelEn {
    switch (this) {
      case PlantShift.shift1_Morning:
        return 'S1';
      case PlantShift.shift2_Evening:
        return 'S2';
      case PlantShift.shift3_Night:
        return 'S3';
    }
  }

  /// Locale-aware short label
  String localizedShortLabel(bool isArabic) =>
      isArabic ? shortLabel : shortLabelEn;

  /// Locale-aware full name
  String localizedName(bool isArabic) =>
      isArabic ? arabicName : englishLabel;

  String get englishLabel {
    switch (this) {
      case PlantShift.shift1_Morning:
        return 'Shift 1 (Morning)';
      case PlantShift.shift2_Evening:
        return 'Shift 2 (Evening)';
      case PlantShift.shift3_Night:
        return 'Shift 3 (Night)';
    }
  }

  String get arabicName {
    switch (this) {
      case PlantShift.shift1_Morning:
        return 'الوردية الأولى (صباحية)';
      case PlantShift.shift2_Evening:
        return 'الوردية الثانية (مسائية)';
      case PlantShift.shift3_Night:
        return 'الوردية الثالثة (ليلية)';
    }
  }

  String get timeRange {
    switch (this) {
      case PlantShift.shift1_Morning:
        return '07:30 - 15:30';
      case PlantShift.shift2_Evening:
        return '15:30 - 23:00';
      case PlantShift.shift3_Night:
        return '23:00 - 07:30';
    }
  }

  Color get color {
    switch (this) {
      case PlantShift.shift1_Morning:
        return AppColors.electricBlue;
      case PlantShift.shift2_Evening:
        return AppColors.downProcessOrange;
      case PlantShift.shift3_Night:
        return AppColors.underRepairPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case PlantShift.shift1_Morning:
        return Icons.wb_sunny_rounded;
      case PlantShift.shift2_Evening:
        return Icons.wb_twilight_rounded;
      case PlantShift.shift3_Night:
        return Icons.nightlight_round;
    }
  }
}
