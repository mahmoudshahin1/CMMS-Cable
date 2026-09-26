import 'package:hive/hive.dart';

@HiveType(typeId: 8)
enum WorkOrderType {
  @HiveField(0)
  breakdown,

  @HiveField(1)
  preventive,

  @HiveField(2)
  corrective,

  @HiveField(3)
  inspection,
}

extension WorkOrderTypeExtension on WorkOrderType {
  String get displayName {
    switch (this) {
      case WorkOrderType.breakdown:
        return 'Breakdown Repair';
      case WorkOrderType.preventive:
        return 'Preventive Maintenance (PM)';
      case WorkOrderType.corrective:
        return 'Corrective Action';
      case WorkOrderType.inspection:
        return 'Routine Inspection';
    }
  }

  String get displayNameAr {
    switch (this) {
      case WorkOrderType.breakdown:
        return 'إصلاح عطل مفاجئ';
      case WorkOrderType.preventive:
        return 'صيانة وقائية';
      case WorkOrderType.corrective:
        return 'إجراء تصحيحي';
      case WorkOrderType.inspection:
        return 'فحص دوري';
    }
  }

  String localizedName(bool isArabic) => isArabic ? displayNameAr : displayName;
}
