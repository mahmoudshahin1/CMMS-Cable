import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class ProcessLogModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String machineId;

  @HiveField(2)
  final String operatorId;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final double meterCount;

  @HiveField(5)
  final double speedMpm;

  @HiveField(6)
  final double? temperatureCelsius;

  @HiveField(7)
  final String? notes;

  const ProcessLogModel({
    required this.id,
    required this.machineId,
    required this.operatorId,
    required this.timestamp,
    required this.meterCount,
    required this.speedMpm,
    this.temperatureCelsius,
    this.notes,
  });

  ProcessLogModel copyWith({
    String? id,
    String? machineId,
    String? operatorId,
    DateTime? timestamp,
    double? meterCount,
    double? speedMpm,
    double? temperatureCelsius,
    String? notes,
  }) {
    return ProcessLogModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      operatorId: operatorId ?? this.operatorId,
      timestamp: timestamp ?? this.timestamp,
      meterCount: meterCount ?? this.meterCount,
      speedMpm: speedMpm ?? this.speedMpm,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'operatorId': operatorId,
      'timestamp': timestamp.toIso8601String(),
      'meterCount': meterCount,
      'speedMpm': speedMpm,
      'temperatureCelsius': temperatureCelsius,
      'notes': notes,
    };
  }

  factory ProcessLogModel.fromJson(Map<String, dynamic> json) {
    return ProcessLogModel(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      operatorId: json['operatorId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      meterCount: (json['meterCount'] as num).toDouble(),
      speedMpm: (json['speedMpm'] as num).toDouble(),
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        machineId,
        operatorId,
        timestamp,
        meterCount,
        speedMpm,
        temperatureCelsius,
        notes,
      ];
}
