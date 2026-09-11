import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
enum UserRole {
  @HiveField(0)
  operator,

  @HiveField(1)
  maintenanceTech,

  @HiveField(2)
  productionSupervisor,

  @HiveField(3)
  maintenanceSupervisor,

  @HiveField(4)
  plantManager;

  // Backward compatibility aliases
  static const UserRole lineOperator = UserRole.operator;
  static const UserRole maintenanceTechnician = UserRole.maintenanceTech;
}

extension UserRoleExtension on UserRole {
  String get code {
    switch (this) {
      case UserRole.operator:
        return 'OPERATOR';
      case UserRole.maintenanceTech:
        return 'MAINTENANCE_TECH';
      case UserRole.productionSupervisor:
        return 'PRODUCTION_SUPERVISOR';
      case UserRole.maintenanceSupervisor:
        return 'MAINTENANCE_SUPERVISOR';
      case UserRole.plantManager:
        return 'PLANT_MANAGER';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.operator:
        return 'Line Operator';
      case UserRole.maintenanceTech:
        return 'Maintenance Technician';
      case UserRole.productionSupervisor:
        return 'Production Supervisor';
      case UserRole.maintenanceSupervisor:
        return 'Maintenance Supervisor';
      case UserRole.plantManager:
        return 'Plant Manager';
    }
  }

  String get badgeTitle {
    switch (this) {
      case UserRole.operator:
        return 'OPERATOR';
      case UserRole.maintenanceTech:
        return 'MAINT TECH';
      case UserRole.productionSupervisor:
        return 'PROD SUP';
      case UserRole.maintenanceSupervisor:
        return 'MAINT SUP';
      case UserRole.plantManager:
        return 'PLANT MGR';
    }
  }

  Color get roleColor {
    switch (this) {
      case UserRole.operator:
        return const Color(0xFFF59E0B); // Amber
      case UserRole.maintenanceTech:
        return const Color(0xFF06B6D4); // Cyber Cyan
      case UserRole.maintenanceSupervisor:
        return const Color(0xFF8B5CF6); // Subdued Violet
      case UserRole.productionSupervisor:
        return const Color(0xFF10B981); // Emerald
      case UserRole.plantManager:
        return const Color(0xFF6366F1); // Indigo / Electric
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.operator:
        return Icons.precision_manufacturing_rounded;
      case UserRole.maintenanceTech:
        return Icons.handyman_rounded;
      case UserRole.maintenanceSupervisor:
        return Icons.engineering_rounded;
      case UserRole.productionSupervisor:
        return Icons.assignment_ind_rounded;
      case UserRole.plantManager:
        return Icons.military_tech_rounded;
    }
  }
}
