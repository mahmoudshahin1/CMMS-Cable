import 'package:hive/hive.dart';
import '../../../features/downtime/domain/models/downtime_log_model.dart';
import '../../../features/downtime/domain/enums/downtime_category.dart';
import '../../chronology/event_chronology.dart';

/// Hive TypeAdapter for [DowntimeLogModel]. TypeId = 7.
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
