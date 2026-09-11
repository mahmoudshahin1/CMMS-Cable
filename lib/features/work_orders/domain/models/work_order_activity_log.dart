import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../../core/chronology/event_chronology.dart';

@HiveType(typeId: 13)
class WorkOrderActivityLog extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String stepName; // e.g. "REPORTED", "ASSIGNED", "REPAIR_STARTED", "SPARE_PART_ADDED", "REPAIR_COMPLETED", "TEST_RUN_PASSED", "CLOSED"

  @HiveField(2)
  final String performedByName; // e.g. "Ahmed Mahmoud"

  @HiveField(3)
  final String performedByEmail; // e.g. "ahmed.op@cableops.local"

  @HiveField(4)
  final String performedByRole; // e.g. "OPERATOR"

  @HiveField(5)
  final DateTime recordedAt; // Exact timestamp

  @HiveField(6)
  final String actionSummary; // Brief readable description

  @HiveField(7)
  final Map<String, dynamic>? details; // Extra fields (root cause, parts, duration)

  @HiveField(8)
  final EventChronology? chronology;

  const WorkOrderActivityLog({
    required this.id,
    required this.stepName,
    required this.performedByName,
    required this.performedByEmail,
    required this.performedByRole,
    required this.recordedAt,
    required this.actionSummary,
    this.details,
    this.chronology,
  });

  EventChronology get effectiveChronology =>
      chronology ?? EventChronology.fromDateTime(recordedAt);

  WorkOrderActivityLog copyWith({
    String? id,
    String? stepName,
    String? performedByName,
    String? performedByEmail,
    String? performedByRole,
    DateTime? recordedAt,
    String? actionSummary,
    Map<String, dynamic>? details,
    EventChronology? chronology,
  }) {
    return WorkOrderActivityLog(
      id: id ?? this.id,
      stepName: stepName ?? this.stepName,
      performedByName: performedByName ?? this.performedByName,
      performedByEmail: performedByEmail ?? this.performedByEmail,
      performedByRole: performedByRole ?? this.performedByRole,
      recordedAt: recordedAt ?? this.recordedAt,
      actionSummary: actionSummary ?? this.actionSummary,
      details: details ?? this.details,
      chronology: chronology ?? this.chronology,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepName': stepName,
      'performedByName': performedByName,
      'performedByEmail': performedByEmail,
      'performedByRole': performedByRole,
      'recordedAt': recordedAt.toIso8601String(),
      'actionSummary': actionSummary,
      'details': details,
      'chronology': chronology?.toJson(),
    };
  }

  factory WorkOrderActivityLog.fromJson(Map<String, dynamic> json) {
    return WorkOrderActivityLog(
      id: json['id'] as String,
      stepName: json['stepName'] as String,
      performedByName: json['performedByName'] as String,
      performedByEmail: json['performedByEmail'] as String,
      performedByRole: json['performedByRole'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      actionSummary: json['actionSummary'] as String,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
      chronology: json['chronology'] != null
          ? EventChronology.fromJson(
              json['chronology'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        stepName,
        performedByName,
        performedByEmail,
        performedByRole,
        recordedAt,
        actionSummary,
        details,
        chronology,
      ];
}
