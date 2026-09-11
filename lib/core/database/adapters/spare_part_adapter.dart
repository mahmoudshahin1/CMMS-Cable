import 'package:hive/hive.dart';
import '../../../features/work_orders/domain/models/spare_part_model.dart';

/// Hive TypeAdapter for [SparePartModel]. TypeId = 11.
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
