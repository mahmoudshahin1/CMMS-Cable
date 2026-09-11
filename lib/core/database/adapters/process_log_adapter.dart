import 'package:hive/hive.dart';
import '../../../features/assets/domain/models/process_log_model.dart';

/// Hive TypeAdapter for [ProcessLogModel]. TypeId = 5.
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
