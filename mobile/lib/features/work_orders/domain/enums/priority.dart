import 'package:hive/hive.dart';

@HiveType(typeId: 10)
enum Priority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high,

  @HiveField(3)
  critical,
}

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical / Emergency';
    }
  }

  String get shortName {
    switch (this) {
      case Priority.low:
        return 'LOW';
      case Priority.medium:
        return 'MEDIUM';
      case Priority.high:
        return 'HIGH';
      case Priority.critical:
        return 'CRITICAL';
    }
  }

  String get displayNameAr {
    switch (this) {
      case Priority.low:
        return 'منخفضة';
      case Priority.medium:
        return 'متوسطة';
      case Priority.high:
        return 'عالية';
      case Priority.critical:
        return 'حرجة / طوارئ';
    }
  }

  String localizedName(bool isArabic) => isArabic ? displayNameAr : displayName;
}
