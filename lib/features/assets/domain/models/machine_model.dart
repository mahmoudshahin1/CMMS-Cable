import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../enums/department_type.dart';
import '../enums/machine_status.dart';

@HiveType(typeId: 4)
class MachineModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final DepartmentType department;

  @HiveField(4)
  final MachineStatus status;

  @HiveField(5)
  final String subCategory;

  @HiveField(6)
  final double currentSpeedMpm;

  @HiveField(7)
  final double totalMetersProduced;

  @HiveField(8)
  final DateTime? lastMaintenanceAt;

  const MachineModel({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.status,
    required this.subCategory,
    this.currentSpeedMpm = 0.0,
    this.totalMetersProduced = 0.0,
    this.lastMaintenanceAt,
  });

  MachineModel copyWith({
    String? id,
    String? code,
    String? name,
    DepartmentType? department,
    MachineStatus? status,
    String? subCategory,
    double? currentSpeedMpm,
    double? totalMetersProduced,
    DateTime? lastMaintenanceAt,
  }) {
    return MachineModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      department: department ?? this.department,
      status: status ?? this.status,
      subCategory: subCategory ?? this.subCategory,
      currentSpeedMpm: currentSpeedMpm ?? this.currentSpeedMpm,
      totalMetersProduced: totalMetersProduced ?? this.totalMetersProduced,
      lastMaintenanceAt: lastMaintenanceAt ?? this.lastMaintenanceAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'department': department.name,
      'status': status.name,
      'subCategory': subCategory,
      'currentSpeedMpm': currentSpeedMpm,
      'totalMetersProduced': totalMetersProduced,
      'lastMaintenanceAt': lastMaintenanceAt?.toIso8601String(),
    };
  }

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      department: DepartmentType.values.firstWhere(
        (e) => e.name == json['department'],
        orElse: () => DepartmentType.drawing,
      ),
      status: MachineStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MachineStatus.running,
      ),
      subCategory: json['subCategory'] as String? ?? '',
      currentSpeedMpm: (json['currentSpeedMpm'] as num?)?.toDouble() ?? 0.0,
      totalMetersProduced: (json['totalMetersProduced'] as num?)?.toDouble() ?? 0.0,
      lastMaintenanceAt: json['lastMaintenanceAt'] != null
          ? DateTime.parse(json['lastMaintenanceAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        department,
        status,
        subCategory,
        currentSpeedMpm,
        totalMetersProduced,
        lastMaintenanceAt,
      ];
}
