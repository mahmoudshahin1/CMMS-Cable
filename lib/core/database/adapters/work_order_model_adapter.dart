import 'package:hive/hive.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/domain/models/spare_part_model.dart';
import '../../../features/work_orders/domain/models/work_order_activity_log.dart';
import '../../../features/work_orders/domain/enums/work_order_type.dart';
import '../../../features/work_orders/domain/enums/work_order_status.dart';
import '../../../features/work_orders/domain/enums/priority.dart';
import '../../chronology/event_chronology.dart';

/// Hive TypeAdapter for [WorkOrderModel]. TypeId = 12.
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
