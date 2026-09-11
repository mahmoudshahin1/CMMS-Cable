import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/chronology/plant_shift.dart';
import '../enums/downtime_category.dart';

@HiveType(typeId: 7)
class DowntimeLogModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String machineId;

  @HiveField(2)
  final String reportedById;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime? endTime;

  @HiveField(5)
  final DowntimeCategory category;

  @HiveField(6)
  final String reason;

  @HiveField(7)
  final bool isMaintenanceRequested;

  @HiveField(8)
  final String? workOrderId;

  @HiveField(9)
  final String? comments;

  @HiveField(10)
  final EventChronology? startChronology;

  @HiveField(11)
  final EventChronology? endChronology;

  const DowntimeLogModel({
    required this.id,
    required this.machineId,
    required this.reportedById,
    required this.startTime,
    this.endTime,
    required this.category,
    required this.reason,
    this.isMaintenanceRequested = false,
    this.workOrderId,
    this.comments,
    this.startChronology,
    this.endChronology,
  });

  EventChronology get effectiveStartChronology =>
      startChronology ?? EventChronology.fromDateTime(startTime);

  EventChronology? get effectiveEndChronology =>
      endChronology ??
      (endTime != null ? EventChronology.fromDateTime(endTime!) : null);

  Duration get duration {
    if (startChronology != null) {
      final endUtc = endChronology?.recordedAtUtc ?? DateTime.now().toUtc();
      return endUtc.difference(startChronology!.recordedAtUtc);
    }
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isActive => endTime == null;

  bool get isCrossShift {
    final origin = effectiveStartChronology;
    final endChrono = effectiveEndChronology;
    if (endChrono != null) {
      return endChrono.isCrossShiftFrom(origin);
    }
    return EventChronology.now().isCrossShiftFrom(origin);
  }

  PlantShift get originShift => effectiveStartChronology.activeShift;

  PlantShift get currentOrEndShift =>
      effectiveEndChronology?.activeShift ?? EventChronology.now().activeShift;

  Map<PlantShift, int> get downtimeMinutesPerShift {
    final startUtc = effectiveStartChronology.recordedAtUtc;
    final endUtc =
        effectiveEndChronology?.recordedAtUtc ?? DateTime.now().toUtc();
    return EventChronology.computeDowntimeMinutesPerShift(startUtc, endUtc);
  }

  DowntimeLogModel copyWith({
    String? id,
    String? machineId,
    String? reportedById,
    DateTime? startTime,
    DateTime? endTime,
    DowntimeCategory? category,
    String? reason,
    bool? isMaintenanceRequested,
    String? workOrderId,
    String? comments,
    EventChronology? startChronology,
    EventChronology? endChronology,
  }) {
    return DowntimeLogModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      reportedById: reportedById ?? this.reportedById,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      isMaintenanceRequested:
          isMaintenanceRequested ?? this.isMaintenanceRequested,
      workOrderId: workOrderId ?? this.workOrderId,
      comments: comments ?? this.comments,
      startChronology: startChronology ?? this.startChronology,
      endChronology: endChronology ?? this.endChronology,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machineId': machineId,
      'reportedById': reportedById,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'category': category.name,
      'reason': reason,
      'isMaintenanceRequested': isMaintenanceRequested,
      'workOrderId': workOrderId,
      'comments': comments,
      'startChronology': startChronology?.toJson(),
      'endChronology': endChronology?.toJson(),
    };
  }

  factory DowntimeLogModel.fromJson(Map<String, dynamic> json) {
    return DowntimeLogModel(
      id: json['id'] as String,
      machineId: json['machineId'] as String,
      reportedById: json['reportedById'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      category: DowntimeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DowntimeCategory.processSetup,
      ),
      reason: json['reason'] as String,
      isMaintenanceRequested: json['isMaintenanceRequested'] as bool? ?? false,
      workOrderId: json['workOrderId'] as String?,
      comments: json['comments'] as String?,
      startChronology: json['startChronology'] != null
          ? EventChronology.fromJson(
              json['startChronology'] as Map<String, dynamic>)
          : null,
      endChronology: json['endChronology'] != null
          ? EventChronology.fromJson(
              json['endChronology'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        machineId,
        reportedById,
        startTime,
        endTime,
        category,
        reason,
        isMaintenanceRequested,
        workOrderId,
        comments,
        startChronology,
        endChronology,
      ];
}
