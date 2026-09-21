import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';

/// Pure mapping logic between Supabase machines rows and MachineModel.
class MachineRemoteMapper {
  static MachineModel fromSupabaseRow(Map<String, dynamic> row) {
    final rawDept = row['department'] as String? ?? 'drawing';
    final rawStatus = row['status'] as String? ?? 'running';

    return MachineModel(
      id: row['id'] as String,
      code: row['code'] as String? ?? row['id'] as String,
      name: row['name'] as String? ?? '',
      department: _parseDepartment(rawDept),
      status: _parseStatus(rawStatus),
      subCategory: row['sub_category'] as String? ?? '',
      currentSpeedMpm: (row['current_speed_mpm'] as num?)?.toDouble() ?? 0.0,
      totalMetersProduced:
          (row['total_meters_produced'] as num?)?.toDouble() ?? 0.0,
      lastMaintenanceAt: row['last_maintenance_at'] != null
          ? DateTime.parse(row['last_maintenance_at'] as String)
          : null,
    );
  }

  static DepartmentType _parseDepartment(String department) {
    return DepartmentType.values.firstWhere(
      (e) => e.name.toLowerCase() == department.toLowerCase(),
      orElse: () => DepartmentType.drawing,
    );
  }

  static MachineStatus _parseStatus(String status) {
    return MachineStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => MachineStatus.running,
    );
  }
}
