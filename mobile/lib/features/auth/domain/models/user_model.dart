import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../enums/user_role.dart';
import '../../../assets/domain/enums/department_type.dart';

@HiveType(typeId: 1)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final UserRole role;

  @HiveField(4)
  final DepartmentType? _department;

  @HiveField(5)
  final String? speciality; // e.g. 'Electrical' or 'Mechanical'

  @HiveField(6)
  final String? employeeCode;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    DepartmentType? department,
    this.speciality,
    this.employeeCode,
  }) : _department = department;

  /// Effective department — automatically resolved for line operators if omitted or null.
  DepartmentType? get department {
    if (_department != null) return _department;
    if (role == UserRole.operator) {
      return DepartmentTypeExtension.resolveOperatorDepartment(
        email: email,
        id: id,
        name: name,
        employeeCode: employeeCode,
      );
    }
    return null;
  }

  /// Alias for [name]
  String get fullName => name;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DepartmentType? department,
    String? speciality,
    String? employeeCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      speciality: speciality ?? this.speciality,
      employeeCode: employeeCode ?? this.employeeCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department?.name,
      'speciality': speciality,
      'employee_code': employeeCode,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.operator,
    );
    final rawDept = json['department'] as String?;
    DepartmentType? department = DepartmentTypeExtension.fromString(rawDept);
    if (department == null && role == UserRole.operator) {
      department = DepartmentTypeExtension.resolveOperatorDepartment(
        email: json['email'] as String?,
        id: json['id'] as String?,
        name: json['name'] as String?,
        employeeCode: json['employee_code'] as String?,
      );
    }
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role,
      department: department,
      speciality: json['speciality'] as String?,
      employeeCode: json['employee_code'] as String?,
    );
  }

  /// Creates a [UserModel] from a Supabase `public.user_profiles` row.
  ///
  /// Expected columns: `id`, `full_name`, `role`, `specialty`, `employee_code`, `department`.
  /// The [email] must be passed separately (from `auth.users`).
  factory UserModel.fromSupabaseProfile(
    Map<String, dynamic> profile, {
    required String email,
  }) {
    final roleStr = (profile['role'] as String?)?.toLowerCase() ?? '';
    final specialtyStr = (profile['specialty'] as String?) ??
        (profile['speciality'] as String?) ??
        '';
    final deptStr = profile['department'] as String?;
    final role = _parseSupabaseRole(roleStr);

    DepartmentType? department = DepartmentTypeExtension.fromString(deptStr);
    if (department == null && role == UserRole.operator) {
      department = DepartmentTypeExtension.resolveOperatorDepartment(
        email: email,
        id: profile['id'] as String?,
        name: (profile['full_name'] as String?) ?? (profile['name'] as String?),
        employeeCode: profile['employee_code'] as String?,
      );
    }

    final id = profile['id'] as String? ?? '';
    final rawName = (profile['full_name'] as String?) ??
        (profile['name'] as String?) ??
        '';
    final effectiveName = rawName.isNotEmpty
        ? rawName
        : (email.isNotEmpty && email.contains('@') ? email.split('@').first : 'User');

    final effectiveEmail = email.isNotEmpty
        ? email
        : (profile['email'] as String? ?? '');

    return UserModel(
      id: id,
      name: effectiveName,
      email: effectiveEmail,
      role: role,
      department: department,
      speciality: specialtyStr.isNotEmpty ? specialtyStr : null,
      employeeCode: profile['employee_code'] as String?,
    );
  }

  /// Maps Supabase role strings to [UserRole] enum values.
  static UserRole _parseSupabaseRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.plantManager;
      case 'SUPERVISOR':
        return UserRole.maintenanceSupervisor;
      case 'TECHNICIAN':
        return UserRole.maintenanceTech;
      case 'OPERATOR':
        return UserRole.operator;
      // Extended roles from existing system
      case 'MAINTENANCE_SUPERVISOR':
        return UserRole.maintenanceSupervisor;
      case 'PRODUCTION_SUPERVISOR':
        return UserRole.productionSupervisor;
      case 'MAINTENANCE_TECH':
        return UserRole.maintenanceTech;
      case 'PLANT_MANAGER':
        return UserRole.plantManager;
      default:
        return UserRole.operator;
    }
  }

  @override
  List<Object?> get props =>
      [id, name, email, role, department, speciality, employeeCode];
}

