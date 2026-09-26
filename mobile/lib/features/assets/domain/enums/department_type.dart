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

  /// Parses a string (English, Arabic, code, or keyword) into a [DepartmentType].
  static DepartmentType? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.trim().toLowerCase();

    // 1. Direct code or enum name match
    for (final dept in DepartmentType.values) {
      if (dept.name.toLowerCase() == clean ||
          dept.code.toLowerCase() == clean ||
          dept.displayName.toLowerCase() == clean ||
          dept.displayNameAr == clean) {
        return dept;
      }
    }

    // 2. Keyword & Arabic heuristic match
    if (clean.contains('draw') || clean.contains('سحب')) {
      return DepartmentType.drawing;
    }
    if (clean.contains('strand') ||
        clean.contains('جدل') ||
        clean.contains('bunch')) {
      return DepartmentType.stranding;
    }
    if (clean.contains('ccv') || clean.contains('فلكنة')) {
      return DepartmentType.ccv;
    }
    if (clean.contains('extru') ||
        clean.contains('عزل') ||
        clean.contains('بثق')) {
      return DepartmentType.extrusion;
    }
    if (clean.contains('assembly') ||
        clean.contains('تجميع') ||
        clean.contains('drum') ||
        clean.contains('bow')) {
      return DepartmentType.assembly;
    }
    if (clean.contains('screen') ||
        clean.contains('حجب') ||
        clean.contains('شريط')) {
      return DepartmentType.screening;
    }
    if (clean.contains('tape') ||
        clean.contains('armour') ||
        clean.contains('تدريع')) {
      return DepartmentType.tapeArmour;
    }

    return null;
  }

  /// Reliably resolves the department for a line operator from email, UUID, name, or code.
  static DepartmentType resolveOperatorDepartment({
    String? email,
    String? id,
    String? name,
    String? employeeCode,
  }) {
    // 1. Infer from email prefix/domain
    if (email != null && email.isNotEmpty) {
      final emailLower = email.toLowerCase();
      if (emailLower.contains('drawing') || emailLower.contains('draw')) {
        return DepartmentType.drawing;
      }
      if (emailLower.contains('stranding') ||
          emailLower.contains('strand') ||
          emailLower.startsWith('operator@')) {
        return DepartmentType.stranding;
      }
      if (emailLower.contains('ccv')) {
        return DepartmentType.ccv;
      }
      if (emailLower.contains('extrusion') || emailLower.contains('extru')) {
        return DepartmentType.extrusion;
      }
      if (emailLower.contains('assembly')) {
        return DepartmentType.assembly;
      }
      if (emailLower.contains('screening') || emailLower.contains('screen')) {
        return DepartmentType.screening;
      }
      if (emailLower.contains('tape') || emailLower.contains('armour')) {
        return DepartmentType.tapeArmour;
      }
    }

    // 2. Infer from ID / UUID
    if (id != null && id.isNotEmpty) {
      final idLower = id.toLowerCase();
      if (idLower.contains('drawing') ||
          idLower == 'ffffffff-ffff-4fff-8fff-ffffffffffff') {
        return DepartmentType.drawing;
      }
      if (idLower.contains('stranding') ||
          idLower == '11111111-1111-4111-8111-111111111111') {
        return DepartmentType.stranding;
      }
      if (idLower.contains('ccv') ||
          idLower == 'b2222222-2222-4222-8222-222222222222') {
        return DepartmentType.ccv;
      }
      if (idLower.contains('extrusion') ||
          idLower == 'c3333333-3333-4333-8333-333333333333') {
        return DepartmentType.extrusion;
      }
      if (idLower.contains('assembly') ||
          idLower == 'd4444444-4444-4444-8444-444444444444') {
        return DepartmentType.assembly;
      }
      if (idLower.contains('screening') ||
          idLower == 'e5555555-5555-4555-8555-555555555555') {
        return DepartmentType.screening;
      }
      if (idLower.contains('tape') ||
          idLower == 'f6666666-6666-4666-8666-666666666666') {
        return DepartmentType.tapeArmour;
      }
    }

    // 3. Infer from name
    if (name != null && name.isNotEmpty) {
      final fromName = fromString(name);
      if (fromName != null) return fromName;
    }

    // 4. Fallback safe default for line operator (never plant-wide)
    return DepartmentType.assembly;
  }
}
