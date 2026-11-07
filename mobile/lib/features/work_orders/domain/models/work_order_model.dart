import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../enums/work_order_type.dart';
import '../enums/work_order_status.dart';
import '../enums/priority.dart';
import 'spare_part_model.dart';
import 'work_order_activity_log.dart';
import 'repair_step_model.dart';
export 'work_order_chronology_extension.dart';

@HiveType(typeId: 12)
class WorkOrderModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String machineId;
  @HiveField(4)
  final String? downtimeLogId;
  @HiveField(5)
  final WorkOrderType type;
  @HiveField(6)
  final WorkOrderStatus status;
  @HiveField(7)
  final Priority priority;
  @HiveField(8)
  final String? assignedToTechnicianId;
  @HiveField(9)
  final String? assignedBySupervisorId;
  @HiveField(10)
  final DateTime createdAt;
  @HiveField(11)
  final DateTime? startedAt;
  @HiveField(12)
  final DateTime? completedAt;
  @HiveField(13)
  final String? rootCause;
  @HiveField(14)
  final String? actionsTaken;
  @HiveField(15)
  final List<SparePartModel> spareParts;
  @HiveField(16)
  final List<WorkOrderActivityLog> activityLogs;
  @HiveField(17)
  final EventChronology? chronology;
  @HiveField(18)
  final int version;
  @HiveField(19)
  final List<Map<String, dynamic>> checks;
  @HiveField(20)
  final List<RepairStepModel> repairSteps;
  @HiveField(21)
  final String? voiceNoteUrl;
  @HiveField(22)
  final String? repairVoiceUrl;
  @HiveField(23)
  final String? voiceNoteLocalPath;

  const WorkOrderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.machineId,
    this.downtimeLogId,
    required this.type,
    required this.status,
    required this.priority,
    this.assignedToTechnicianId,
    this.assignedBySupervisorId,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.rootCause,
    this.actionsTaken,
    this.spareParts = const [],
    this.activityLogs = const [],
    this.chronology,
    this.version = 1,
    this.checks = const [],
    this.repairSteps = const [],
    this.voiceNoteUrl,
    this.repairVoiceUrl,
    this.voiceNoteLocalPath,
  });

  Map<String, dynamic>? get latestCheck =>
      checks.isNotEmpty ? checks.last : null;

  String? get latestRejectionNotes {
    if (status != WorkOrderStatus.inProgress) return null;
    for (final check in checks.reversed) {
      final outcome = check['outcome'] as String?;
      if (outcome == 'needs_followup' || outcome == 'not_fixed') {
        final notes = check['notes'] as String?;
        if (notes != null && notes.trim().isNotEmpty) return notes;
      }
    }
    for (final log in activityLogs.reversed) {
      if (log.stepName == 'TEST_RUN_REJECTED') {
        final c = log.details?['comments'] as String?;
        if (c != null && c.trim().isNotEmpty) return c;
        return log.actionSummary;
      }
    }
    return null;
  }

  WorkOrderModel copyWith({
    String? id,
    String? title,
    String? description,
    String? machineId,
    String? downtimeLogId,
    WorkOrderType? type,
    WorkOrderStatus? status,
    Priority? priority,
    String? assignedToTechnicianId,
    String? assignedBySupervisorId,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? rootCause,
    String? actionsTaken,
    List<SparePartModel>? spareParts,
    List<WorkOrderActivityLog>? activityLogs,
    EventChronology? chronology,
    int? version,
    List<Map<String, dynamic>>? checks,
    List<RepairStepModel>? repairSteps,
    String? voiceNoteUrl,
    String? repairVoiceUrl,
    String? voiceNoteLocalPath,
  }) {
    return WorkOrderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      machineId: machineId ?? this.machineId,
      downtimeLogId: downtimeLogId ?? this.downtimeLogId,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedToTechnicianId:
          assignedToTechnicianId ?? this.assignedToTechnicianId,
      assignedBySupervisorId:
          assignedBySupervisorId ?? this.assignedBySupervisorId,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rootCause: rootCause ?? this.rootCause,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      spareParts: spareParts ?? this.spareParts,
      activityLogs: activityLogs ?? this.activityLogs,
      chronology: chronology ?? this.chronology,
      version: version ?? this.version,
      checks: checks ?? this.checks,
      repairSteps: repairSteps ?? this.repairSteps,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      repairVoiceUrl: repairVoiceUrl ?? this.repairVoiceUrl,
      voiceNoteLocalPath: voiceNoteLocalPath ?? this.voiceNoteLocalPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'machineId': machineId,
      'downtimeLogId': downtimeLogId,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'assignedToTechnicianId': assignedToTechnicianId,
      'assignedBySupervisorId': assignedBySupervisorId,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rootCause': rootCause,
      'actionsTaken': actionsTaken,
      'spareParts': spareParts.map((e) => e.toJson()).toList(),
      'activityLogs': activityLogs.map((e) => e.toJson()).toList(),
      'chronology': chronology?.toJson(),
      'version': version,
      'checks': checks,
      'repair_steps': repairSteps.map((e) => e.toJson()).toList(),
      'voice_note_url': voiceNoteUrl,
      'repair_voice_url': repairVoiceUrl,
      'voice_note_local_path': voiceNoteLocalPath,
    };
  }

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      machineId: json['machineId'] as String,
      downtimeLogId: json['downtimeLogId'] as String?,
      type: WorkOrderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WorkOrderType.breakdown,
      ),
      status: WorkOrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkOrderStatus.open,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      assignedToTechnicianId: json['assignedToTechnicianId'] as String?,
      assignedBySupervisorId: json['assignedBySupervisorId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      rootCause: json['rootCause'] as String?,
      actionsTaken: json['actionsTaken'] as String?,
      spareParts:
          (json['spareParts'] as List<dynamic>?)
              ?.map((e) => SparePartModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activityLogs:
          (json['activityLogs'] as List<dynamic>?)
              ?.map(
                (e) => WorkOrderActivityLog.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      chronology: json['chronology'] != null
          ? EventChronology.fromJson(json['chronology'] as Map<String, dynamic>)
          : null,
      version: (json['version'] as num?)?.toInt() ?? 1,
      checks:
          (json['checks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      repairSteps:
          (json['repair_steps'] as List<dynamic>?)
              ?.map(
                (e) => RepairStepModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      voiceNoteUrl: json['voice_note_url'] as String?,
      repairVoiceUrl: json['repair_voice_url'] as String?,
      voiceNoteLocalPath: json['voice_note_local_path'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    machineId,
    downtimeLogId,
    type,
    status,
    priority,
    assignedToTechnicianId,
    assignedBySupervisorId,
    createdAt,
    startedAt,
    completedAt,
    rootCause,
    actionsTaken,
    spareParts,
    activityLogs,
    chronology,
    version,
    checks,
    repairSteps,
    voiceNoteUrl,
    repairVoiceUrl,
    voiceNoteLocalPath,
  ];
}
