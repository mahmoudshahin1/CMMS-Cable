import 'package:hive/hive.dart';
import '../../../features/assets/domain/models/machine_model.dart';
import '../../../features/assets/domain/enums/department_type.dart';
import '../../../features/assets/domain/enums/machine_status.dart';

/// Hive TypeAdapter for [MachineModel]. TypeId = 4.
class MachineModelAdapter extends TypeAdapter<MachineModel> {
  @override
  final int typeId = 4;

  @override
  MachineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MachineModel(
      id: fields[0] as String,
      code: fields[1] as String,
      name: fields[2] as String,
      department: fields[3] as DepartmentType,
      status: fields[4] as MachineStatus,
      subCategory: fields[5] as String,
      currentSpeedMpm: (fields[6] as num?)?.toDouble() ?? 0.0,
      totalMetersProduced: (fields[7] as num?)?.toDouble() ?? 0.0,
      lastMaintenanceAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MachineModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.subCategory)
      ..writeByte(6)
      ..write(obj.currentSpeedMpm)
      ..writeByte(7)
      ..write(obj.totalMetersProduced)
      ..writeByte(8)
      ..write(obj.lastMaintenanceAt);
  }
}
