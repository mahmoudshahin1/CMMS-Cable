import 'package:hive/hive.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../features/auth/domain/enums/user_role.dart';
import '../../../features/assets/domain/models/machine_model.dart';
import '../../../features/assets/domain/enums/department_type.dart';
import '../../../features/assets/domain/enums/machine_status.dart';
import '../../../features/assets/domain/models/process_log_model.dart';
import '../../../features/downtime/domain/models/downtime_log_model.dart';
import '../../../features/downtime/domain/enums/downtime_category.dart';
import '../../../features/work_orders/domain/models/spare_part_model.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/domain/models/work_order_activity_log.dart';
import '../../../features/work_orders/domain/enums/work_order_type.dart';
import '../../../features/work_orders/domain/enums/work_order_status.dart';
import '../../../features/work_orders/domain/enums/priority.dart';
import '../../chronology/event_chronology.dart';
import '../../chronology/plant_shift.dart';

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

class ProcessLogModelAdapter extends TypeAdapter<ProcessLogModel> {
  @override
  final int typeId = 5;

  @override
  ProcessLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProcessLogModel(
      id: fields[0] as String,
      machineId: fields[1] as String,
      operatorId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      meterCount: (fields[4] as num).toDouble(),
      speedMpm: (fields[5] as num).toDouble(),
      temperatureCelsius: (fields[6] as num?)?.toDouble(),
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProcessLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.machineId)
      ..writeByte(2)
      ..write(obj.operatorId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.meterCount)
      ..writeByte(5)
      ..write(obj.speedMpm)
      ..writeByte(6)
      ..write(obj.temperatureCelsius)
      ..writeByte(7)
      ..write(obj.notes);
  }
}

class DowntimeLogModelAdapter extends TypeAdapter<DowntimeLogModel> {
  @override
  final int typeId = 7;

  @override
  DowntimeLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final startTime = fields[3] as DateTime;
    final endTime = fields[4] as DateTime?;
    return DowntimeLogModel(
      id: fields[0] as String,
      machineId: fields[1] as String,
      reportedById: fields[2] as String,
      startTime: startTime,
      endTime: endTime,
      category: fields[5] as DowntimeCategory,
      reason: fields[6] as String,
      isMaintenanceRequested: fields[7] as bool,
      workOrderId: fields[8] as String?,
      comments: fields[9] as String?,
      startChronology: fields[10] as EventChronology? ??
          EventChronology.fromDateTime(startTime),
      endChronology: fields[11] as EventChronology? ??
          (endTime != null ? EventChronology.fromDateTime(endTime) : null),
    );
  }

  @override
  void write(BinaryWriter writer, DowntimeLogModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.machineId)
      ..writeByte(2)
      ..write(obj.reportedById)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.isMaintenanceRequested)
      ..writeByte(8)
      ..write(obj.workOrderId)
      ..writeByte(9)
      ..write(obj.comments)
      ..writeByte(10)
      ..write(obj.startChronology)
      ..writeByte(11)
      ..write(obj.endChronology);
  }
}

class SparePartModelAdapter extends TypeAdapter<SparePartModel> {
  @override
  final int typeId = 11;

  @override
  SparePartModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SparePartModel(
      id: fields[0] as String,
      partNumber: fields[1] as String,
      name: fields[2] as String,
      quantityUsed: fields[3] as int,
      unitCost: (fields[4] as num?)?.toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SparePartModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.partNumber)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantityUsed)
      ..writeByte(4)
      ..write(obj.unitCost);
  }
}

class WorkOrderModelAdapter extends TypeAdapter<WorkOrderModel> {
  @override
  final int typeId = 12;

  @override
  WorkOrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final createdAt = fields[10] as DateTime;
    return WorkOrderModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      machineId: fields[3] as String,
      downtimeLogId: fields[4] as String?,
      type: fields[5] as WorkOrderType,
      status: fields[6] as WorkOrderStatus,
      priority: fields[7] as Priority,
      assignedToTechnicianId: fields[8] as String?,
      assignedBySupervisorId: fields[9] as String?,
      createdAt: createdAt,
      startedAt: fields[11] as DateTime?,
      completedAt: fields[12] as DateTime?,
      rootCause: fields[13] as String?,
      actionsTaken: fields[14] as String?,
      spareParts: fields[15] != null
          ? (fields[15] as List).cast<SparePartModel>()
          : const <SparePartModel>[],
      activityLogs: fields[16] != null
          ? (fields[16] as List).cast<WorkOrderActivityLog>()
          : const <WorkOrderActivityLog>[],
      chronology: fields[17] as EventChronology? ??
          EventChronology.fromDateTime(createdAt),
    );
  }

  @override
  void write(BinaryWriter writer, WorkOrderModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.machineId)
      ..writeByte(4)
      ..write(obj.downtimeLogId)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.assignedToTechnicianId)
      ..writeByte(9)
      ..write(obj.assignedBySupervisorId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.startedAt)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.rootCause)
      ..writeByte(14)
      ..write(obj.actionsTaken)
      ..writeByte(15)
      ..write(obj.spareParts)
      ..writeByte(16)
      ..write(obj.activityLogs)
      ..writeByte(17)
      ..write(obj.chronology);
  }
}

class WorkOrderActivityLogAdapter extends TypeAdapter<WorkOrderActivityLog> {
  @override
  final int typeId = 13;

  @override
  WorkOrderActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final recordedAt = fields[5] as DateTime;
    return WorkOrderActivityLog(
      id: fields[0] as String,
      stepName: fields[1] as String,
      performedByName: fields[2] as String,
      performedByEmail: fields[3] as String,
      performedByRole: fields[4] as String,
      recordedAt: recordedAt,
      actionSummary: fields[6] as String,
      details: fields[7] != null
          ? Map<String, dynamic>.from(fields[7] as Map)
          : null,
      chronology: fields[8] as EventChronology? ??
          EventChronology.fromDateTime(recordedAt),
    );
  }

  @override
  void write(BinaryWriter writer, WorkOrderActivityLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stepName)
      ..writeByte(2)
      ..write(obj.performedByName)
      ..writeByte(3)
      ..write(obj.performedByEmail)
      ..writeByte(4)
      ..write(obj.performedByRole)
      ..writeByte(5)
      ..write(obj.recordedAt)
      ..writeByte(6)
      ..write(obj.actionSummary)
      ..writeByte(7)
      ..write(obj.details)
      ..writeByte(8)
      ..write(obj.chronology);
  }
}

class EventChronologyAdapter extends TypeAdapter<EventChronology> {
  @override
  final int typeId = 15;

  @override
  EventChronology read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventChronology(
      recordedAtUtc: fields[0] as DateTime,
      plantTimeFormatted: fields[1] as String,
      productionDate: fields[2] as String,
      activeShift: fields[3] as PlantShift,
      isOfflineGenerated: fields[4] as bool? ?? false,
      syncedAtUtc: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EventChronology obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.recordedAtUtc)
      ..writeByte(1)
      ..write(obj.plantTimeFormatted)
      ..writeByte(2)
      ..write(obj.productionDate)
      ..writeByte(3)
      ..write(obj.activeShift)
      ..writeByte(4)
      ..write(obj.isOfflineGenerated)
      ..writeByte(5)
      ..write(obj.syncedAtUtc);
  }
}
