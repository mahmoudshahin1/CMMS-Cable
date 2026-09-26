import 'package:hive/hive.dart';

@HiveType(typeId: 6)
enum DowntimeCategory {
  @HiveField(0)
  processSetup,

  @HiveField(1)
  processMaterialShortage,

  @HiveField(2)
  processQualityHold,

  @HiveField(3)
  mechanicalBreakdown,

  @HiveField(4)
  electricalBreakdown,

  @HiveField(5)
  utilityFailure,

  @HiveField(6)
  plannedMaintenance,
}

extension DowntimeCategoryExtension on DowntimeCategory {
  String get displayName {
    switch (this) {
      case DowntimeCategory.processSetup:
        return 'Process / Setup Change';
      case DowntimeCategory.processMaterialShortage:
        return 'Material Shortage';
      case DowntimeCategory.processQualityHold:
        return 'Quality Hold';
      case DowntimeCategory.mechanicalBreakdown:
        return 'Mechanical Breakdown';
      case DowntimeCategory.electricalBreakdown:
        return 'Electrical Breakdown';
      case DowntimeCategory.utilityFailure:
        return 'Utility Failure (Power/Air/Water)';
      case DowntimeCategory.plannedMaintenance:
        return 'Planned Maintenance';
    }
  }

  String get displayNameAr {
    switch (this) {
      case DowntimeCategory.processSetup:
        return 'تجهيز وتشغيل / تغيير مقاس';
      case DowntimeCategory.processMaterialShortage:
        return 'نقص مواد وخامات';
      case DowntimeCategory.processQualityHold:
        return 'توقف جودة وفحص';
      case DowntimeCategory.mechanicalBreakdown:
        return 'عطل ميكانيكي';
      case DowntimeCategory.electricalBreakdown:
        return 'عطل كهربائي';
      case DowntimeCategory.utilityFailure:
        return 'عطل مرافق (كهرباء/هواء/مياه)';
      case DowntimeCategory.plannedMaintenance:
        return 'صيانة وقائية مخططة';
    }
  }

  String localizedName(bool isArabic) => isArabic ? displayNameAr : displayName;

  bool get isMaintenance =>
      this == DowntimeCategory.mechanicalBreakdown ||
      this == DowntimeCategory.electricalBreakdown ||
      this == DowntimeCategory.utilityFailure ||
      this == DowntimeCategory.plannedMaintenance;
}
