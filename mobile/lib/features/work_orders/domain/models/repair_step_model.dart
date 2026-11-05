import 'package:equatable/equatable.dart';

/// Structured single step taken during a maintenance repair.
class RepairStepModel extends Equatable {
  final String id;
  final String description;
  final String? partName;
  final String? partNumber;
  final int? quantity;
  final DateTime? completedAt;

  const RepairStepModel({
    required this.id,
    required this.description,
    this.partName,
    this.partNumber,
    this.quantity,
    this.completedAt,
  });

  RepairStepModel copyWith({
    String? id,
    String? description,
    String? partName,
    String? partNumber,
    int? quantity,
    DateTime? completedAt,
  }) {
    return RepairStepModel(
      id: id ?? this.id,
      description: description ?? this.description,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      quantity: quantity ?? this.quantity,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'part_name': partName,
      'part_number': partNumber,
      'quantity': quantity,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory RepairStepModel.fromJson(Map<String, dynamic> json) {
    return RepairStepModel(
      id: (json['id'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      partName: json['part_name'] as String?,
      partNumber: json['part_number'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        partName,
        partNumber,
        quantity,
        completedAt,
      ];
}

