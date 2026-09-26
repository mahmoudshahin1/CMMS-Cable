import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 11)
class SparePartModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String partNumber;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int quantityUsed;

  @HiveField(4)
  final double? unitCost;

  const SparePartModel({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.quantityUsed,
    this.unitCost,
  });

  double get totalPrice => (unitCost ?? 0.0) * quantityUsed;

  SparePartModel copyWith({
    String? id,
    String? partNumber,
    String? name,
    int? quantityUsed,
    double? unitCost,
  }) {
    return SparePartModel(
      id: id ?? this.id,
      partNumber: partNumber ?? this.partNumber,
      name: name ?? this.name,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partNumber': partNumber,
      'name': name,
      'quantityUsed': quantityUsed,
      'unitCost': unitCost,
    };
  }

  factory SparePartModel.fromJson(Map<String, dynamic> json) {
    return SparePartModel(
      id: json['id'] as String,
      partNumber: json['partNumber'] as String,
      name: json['name'] as String,
      quantityUsed: json['quantityUsed'] as int,
      unitCost: (json['unitCost'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, partNumber, name, quantityUsed, unitCost];
}
