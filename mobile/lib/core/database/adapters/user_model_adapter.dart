import 'package:hive/hive.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/assets/domain/enums/department_type.dart';

/// Hive TypeAdapter for [UserModel]. TypeId = 1.
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      role: fields[3] as UserRole,
      department: fields[4] as DepartmentType?,
      speciality: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.department)
      ..writeByte(5)
      ..write(obj.speciality);
  }
}
