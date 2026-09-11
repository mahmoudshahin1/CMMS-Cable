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
  final DepartmentType? department;

  @HiveField(5)
  final String? speciality; // e.g. 'Electrical' or 'Mechanical'

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.speciality,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DepartmentType? department,
    String? speciality,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      speciality: speciality ?? this.speciality,
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
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.operator,
      ),
      department: json['department'] != null
          ? DepartmentType.values.firstWhere(
              (e) => e.name == json['department'],
              orElse: () => DepartmentType.drawing,
            )
          : null,
      speciality: json['speciality'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, department, speciality];
}
