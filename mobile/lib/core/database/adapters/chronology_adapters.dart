import 'package:hive/hive.dart';
import '../../chronology/event_chronology.dart';
import '../../chronology/plant_shift.dart';

/// Hive TypeAdapter for [EventChronology]. TypeId = 15.
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
