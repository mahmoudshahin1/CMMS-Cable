import 'dart:convert';
import 'package:hive/hive.dart';
import '../../sync/outbox/outbox_command.dart';

/// Hive TypeAdapter for [OutboxCommandStatus]. TypeId = 17.
class OutboxCommandStatusAdapter extends TypeAdapter<OutboxCommandStatus> {
  @override
  final int typeId = 17;

  @override
  OutboxCommandStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < OutboxCommandStatus.values.length) {
      return OutboxCommandStatus.values[index];
    }
    return OutboxCommandStatus.failed;
  }

  @override
  void write(BinaryWriter writer, OutboxCommandStatus obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for [OutboxCommand]. TypeId = 16.
class OutboxCommandAdapter extends TypeAdapter<OutboxCommand> {
  @override
  final int typeId = 16;

  @override
  OutboxCommand read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    Map<String, dynamic> payloadMap;
    try {
      final rawPayload = fields[3];
      if (rawPayload is String) {
        payloadMap = jsonDecode(rawPayload) as Map<String, dynamic>;
      } else if (rawPayload is Map) {
        payloadMap = Map<String, dynamic>.from(rawPayload);
      } else {
        payloadMap = {};
      }
    } catch (_) {
      payloadMap = {};
    }

    return OutboxCommand(
      commandId: fields[0] as String,
      commandType: fields[1] as String,
      aggregateId: fields[2] as String,
      payload: payloadMap,
      occurredAt: fields[4] as DateTime,
      status: fields[5] as OutboxCommandStatus,
      attempts: (fields[6] as int?) ?? 0,
      lastError: fields[7] as String?,
      expectedVersion: fields[8] as int?,
      processedAt: fields[9] as DateTime?,
      nextRetryAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OutboxCommand obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.commandId)
      ..writeByte(1)
      ..write(obj.commandType)
      ..writeByte(2)
      ..write(obj.aggregateId)
      ..writeByte(3)
      ..write(jsonEncode(obj.payload))
      ..writeByte(4)
      ..write(obj.occurredAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.attempts)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.expectedVersion)
      ..writeByte(9)
      ..write(obj.processedAt)
      ..writeByte(10)
      ..write(obj.nextRetryAt);
  }
}
