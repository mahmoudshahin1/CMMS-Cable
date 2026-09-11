import 'package:hive/hive.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/assets/domain/enums/department_type.dart';
import '../../../features/assets/domain/enums/machine_status.dart';
import '../../../features/downtime/domain/enums/downtime_category.dart';
import '../../../features/work_orders/domain/enums/work_order_type.dart';
import '../../../features/work_orders/domain/enums/work_order_status.dart';
import '../../../features/work_orders/domain/enums/priority.dart';
import '../../chronology/plant_shift.dart';

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 0;

  @override
  UserRole read(BinaryReader reader) {
    return UserRole.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    writer.writeByte(obj.index);
  }
}

class DepartmentTypeAdapter extends TypeAdapter<DepartmentType> {
  @override
  final int typeId = 2;

  @override
  DepartmentType read(BinaryReader reader) {
    return DepartmentType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, DepartmentType obj) {
    writer.writeByte(obj.index);
  }
}

class MachineStatusAdapter extends TypeAdapter<MachineStatus> {
  @override
  final int typeId = 3;

  @override
  MachineStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < MachineStatus.values.length) {
      return MachineStatus.values[index];
    }
    return MachineStatus.running;
  }

  @override
  void write(BinaryWriter writer, MachineStatus obj) {
    writer.writeByte(obj.index);
  }
}

class DowntimeCategoryAdapter extends TypeAdapter<DowntimeCategory> {
  @override
  final int typeId = 6;

  @override
  DowntimeCategory read(BinaryReader reader) {
    return DowntimeCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, DowntimeCategory obj) {
    writer.writeByte(obj.index);
  }
}

class WorkOrderTypeAdapter extends TypeAdapter<WorkOrderType> {
  @override
  final int typeId = 8;

  @override
  WorkOrderType read(BinaryReader reader) {
    return WorkOrderType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, WorkOrderType obj) {
    writer.writeByte(obj.index);
  }
}

class WorkOrderStatusAdapter extends TypeAdapter<WorkOrderStatus> {
  @override
  final int typeId = 9;

  @override
  WorkOrderStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < WorkOrderStatus.values.length) {
      return WorkOrderStatus.values[index];
    }
    return WorkOrderStatus.open;
  }

  @override
  void write(BinaryWriter writer, WorkOrderStatus obj) {
    writer.writeByte(obj.index);
  }
}

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 10;

  @override
  Priority read(BinaryReader reader) {
    return Priority.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    writer.writeByte(obj.index);
  }
}

class PlantShiftAdapter extends TypeAdapter<PlantShift> {
  @override
  final int typeId = 14;

  @override
  PlantShift read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < PlantShift.values.length) {
      return PlantShift.values[index];
    }
    return PlantShift.shiftA;
  }

  @override
  void write(BinaryWriter writer, PlantShift obj) {
    writer.writeByte(obj.index);
  }
}
