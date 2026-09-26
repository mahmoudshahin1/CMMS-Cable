import 'package:hive/hive.dart';
import '../../../features/work_orders/domain/models/work_order_activity_log.dart';
import '../../chronology/event_chronology.dart';

/// Hive TypeAdapter for [WorkOrderActivityLog]. TypeId = 13.
class WorkOrderActivityLogAdapter
    extends TypeAdapter<WorkOrderActivityLog> {
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
