import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/models/work_order_activity_log.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/enums/work_order_type.dart';
import '../../domain/enums/priority.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/auth/user_directory_helper.dart';
import '../../../../features/auth/domain/enums/user_role.dart';

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

    final rawVersion = row['version'];
    final version = (rawVersion as num?)?.toInt() ?? 1;

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
      version: version,
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

    final actorId = (row['actor_id'] as String?) ?? (payload?['actor_id'] as String?);
    final cachedUser = actorId != null ? UserDirectoryHelper.getUser(actorId) : null;

    // Resolve Name
    String resolvedName = (payload?['actor_name'] as String?) ??
        cachedUser?.name ??
        (actorId != null ? UserDirectoryHelper.resolveName(actorId) : null) ??
        '';

    if (resolvedName.isEmpty || resolvedName == 'System User') {
      if (payload?['supervisor'] is String && (payload!['supervisor'] as String).trim().isNotEmpty) {
        resolvedName = payload['supervisor'] as String;
      } else if (payload?['technician'] is String && (payload!['technician'] as String).trim().isNotEmpty) {
        resolvedName = payload['technician'] as String;
      } else if (actorId != null && actorId == UserDirectoryHelper.currentUser?.id) {
        resolvedName = UserDirectoryHelper.currentUser!.name;
      } else {
        resolvedName = 'System User';
      }
    }

    // Resolve Email
    String resolvedEmail = (payload?['actor_email'] as String?) ??
        cachedUser?.email ??
        (actorId == UserDirectoryHelper.currentUser?.id ? UserDirectoryHelper.currentUser?.email : null) ??
        'system@cableops.local';

    // Resolve Role
    String resolvedRole = (payload?['actor_role'] as String?) ??
        cachedUser?.role.code ??
        (actorId == UserDirectoryHelper.currentUser?.id ? UserDirectoryHelper.currentUser?.role.code : null) ??
        '';

    if (resolvedRole.isEmpty || resolvedRole == 'SYSTEM') {
      final eventType = (row['event_type'] as String? ?? '').toUpperCase();
      if (eventType.contains('REPAIR') || eventType.contains('PART')) {
        resolvedRole = 'MAINTENANCE_TECH';
      } else if (eventType.contains('TEST') || eventType.contains('REPORTED')) {
        resolvedRole = 'OPERATOR';
      } else if (eventType.contains('ASSIGN') || eventType.contains('CLOSE')) {
        resolvedRole = 'MAINTENANCE_SUPERVISOR';
      } else {
        resolvedRole = 'SYSTEM';
      }
    }

    final rawSummary = (payload?['summary'] as String?) ?? row['event_type'] as String? ?? '';
    final formattedSummary = UserDirectoryHelper.formatActionSummary(rawSummary);

    return WorkOrderActivityLog(
      id: row['id'] as String? ?? '',
      stepName: row['event_type'] as String? ?? 'EVENT',
      performedByName: resolvedName,
      performedByEmail: resolvedEmail,
      performedByRole: resolvedRole,
      recordedAt: occurred,
      actionSummary: formattedSummary,
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
