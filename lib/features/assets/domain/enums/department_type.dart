import 'package:hive/hive.dart';

@HiveType(typeId: 2)
enum DepartmentType {
  @HiveField(0)
  drawing,

  @HiveField(1)
  stranding,

  @HiveField(2)
  ccv,

  @HiveField(3)
  extrusion,

  @HiveField(4)
  assembly,

  @HiveField(5)
  screening,

  @HiveField(6)
  tapeArmour,
}

extension DepartmentTypeExtension on DepartmentType {
  String get displayName {
    switch (this) {
      case DepartmentType.drawing:
        return 'Drawing Department';
      case DepartmentType.stranding:
        return 'Stranding & Bunching';
      case DepartmentType.ccv:
        return 'CCV Lines (HV/EHV)';
      case DepartmentType.extrusion:
        return 'Extrusion Lines';
      case DepartmentType.assembly:
        return 'Assembly & Armouring';
      case DepartmentType.screening:
        return 'Screening & Taping';
      case DepartmentType.tapeArmour:
        return 'Tape Armouring';
    }
  }

  String get displayNameAr {
    switch (this) {
      case DepartmentType.drawing:
        return 'قسم سحب الأسلاك';
      case DepartmentType.stranding:
        return 'قسم الجدل والتجميع';
      case DepartmentType.ccv:
        return 'خطوط الفلكنة المستمرة (CCV)';
      case DepartmentType.extrusion:
        return 'خطوط العزل والبثق';
      case DepartmentType.assembly:
        return 'قسم التجميع والتسليح';
      case DepartmentType.screening:
        return 'قسم الحجب والشريط';
      case DepartmentType.tapeArmour:
        return 'قسم تدريع الأشرطة';
    }
  }

  String localizedName(bool isArabic) => isArabic ? displayNameAr : displayName;

  String get code {
    switch (this) {
      case DepartmentType.drawing:
        return 'drawing';
      case DepartmentType.stranding:
        return 'stranding';
      case DepartmentType.ccv:
        return 'ccv';
      case DepartmentType.extrusion:
        return 'extrusion';
      case DepartmentType.assembly:
        return 'assembly';
      case DepartmentType.screening:
        return 'screening';
      case DepartmentType.tapeArmour:
        return 'tapeArmour';
    }
  }
}
