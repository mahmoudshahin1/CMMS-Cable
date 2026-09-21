import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/models/work_order_activity_log.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/enums/priority.dart';
import '../../../../core/chronology/event_chronology.dart';

/// Pure mapping logic between Supabase JSON representations and domain models.
class WorkOrderRemoteMapper {
  static WorkOrderModel fromSupabaseRow(
    Map<String, dynamic> row, {
    List<Map<String, dynamic>> partsRows = const [],
    List<Map<String, dynamic>> eventsRows = const [],
  }) {
    final rawStatus = row['status'] as String? ?? 'open';
    final rawType = row['type'] as String? ?? 'breakdown';
    final rawPriority = row['priority'] as String? ?? 'medium';

    final spareParts = partsRows.map(sparePartFromRow).toList();
    final activityLogs = eventsRows.map(activityLogFromRow).toList();

    EventChronology? chrono;
    final rawChrono = row['chronology'];
    if (rawChrono is Map<String, dynamic>) {
      chrono = EventChronology.fromJson(rawChrono);
    }

    return WorkOrderModel(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      machineId: row['machine_id'] as String? ?? '',
      type: _parseType(rawType),
      status: _parseStatus(rawStatus),
      priority: _parsePriority(rawPriority),
      assignedToTechnicianId: row['assigned_to_technician_id'] as String?,
      assignedBySupervisorId: row['assigned_by_supervisor_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      startedAt: row['started_at'] != null
          ? DateTime.parse(row['started_at'] as String)
          : null,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      rootCause: row['root_cause'] as String?,
      actionsTaken: row['actions_taken'] as String?,
      spareParts: spareParts,
      activityLogs: activityLogs,
      chronology: chrono,
    );
  }

  static SparePartModel sparePartFromRow(Map<String, dynamic> row) {
    return SparePartModel(
      id: row['id'] as String? ?? '',
      partNumber: row['part_code'] as String? ?? '',
      name: row['part_name'] as String? ?? '',
      quantityUsed: (row['quantity'] as num?)?.toInt() ?? 1,
      unitCost: (row['unit_cost'] as num?)?.toDouble(),
    );
  }

  static WorkOrderActivityLog activityLogFromRow(Map<String, dynamic> row) {
    EventChronology? chrono;
    final payload = row['payload'] is Map ? row['payload'] as Map : null;
    if (payload != null && payload['chronology'] is Map) {
      chrono = EventChronology.fromJson(
        Map<String, dynamic>.from(payload['chronology'] as Map),
      );
    }

    final rawOccurred = row['occurred_at'] as String?;
    final occurred = rawOccurred != null
        ? DateTime.parse(rawOccurred)
        : DateTime.now();

    return WorkOrderActivityLog(
      id: row['id'] as String? ?? '',
      stepName: row['event_type'] as String? ?? 'EVENT',
      performedByName: (payload?['actor_name'] as String?) ?? 'System User',
      performedByEmail: (payload?['actor_email'] as String?) ?? 'system@cableops.local',
      performedByRole: (payload?['actor_role'] as String?) ?? 'SYSTEM',
      recordedAt: occurred,
      actionSummary: (payload?['summary'] as String?) ?? row['event_type'] as String? ?? '',
      details: payload != null ? Map<String, dynamic>.from(payload) : null,
      chronology: chrono,
    );
  }

  static WorkOrderStatus _parseStatus(String status) {
    return WorkOrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => WorkOrderStatus.open,
    );
  }

  static WorkOrderType _parseType(String type) {
    return WorkOrderType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => WorkOrderType.breakdown,
    );
  }

  static Priority _parsePriority(String priority) {
    return Priority.values.firstWhere(
      (e) => e.name.toLowerCase() == priority.toLowerCase(),
      orElse: () => Priority.medium,
    );
  }
}
