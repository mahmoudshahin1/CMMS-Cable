import '../../domain/models/downtime_log_model.dart';
import '../../domain/enums/downtime_category.dart';
import '../../../../core/chronology/event_chronology.dart';

/// Pure mapping logic between Supabase downtime_logs rows and DowntimeLogModel.
class DowntimeRemoteMapper {
  static DowntimeLogModel fromSupabaseRow(Map<String, dynamic> row) {
    EventChronology? startChrono;
    if (row['start_chronology'] is Map<String, dynamic>) {
      startChrono = EventChronology.fromJson(row['start_chronology']);
    }

    EventChronology? endChrono;
    if (row['end_chronology'] is Map<String, dynamic>) {
      endChrono = EventChronology.fromJson(row['end_chronology']);
    }

    final rawCategory = row['category'] as String? ?? 'other';

    return DowntimeLogModel(
      id: row['id'] as String,
      machineId: row['machine_id'] as String? ?? '',
      reportedById: row['created_by'] as String? ?? '',
      startTime: DateTime.parse(row['started_at'] as String),
      endTime: row['ended_at'] != null
          ? DateTime.parse(row['ended_at'] as String)
          : null,
      category: _parseCategory(rawCategory),
      reason: row['reason'] as String? ?? '',
      isMaintenanceRequested:
          row['is_maintenance_requested'] as bool? ?? false,
      workOrderId: row['work_order_id'] as String?,
      comments: row['comments'] as String?,
      startChronology: startChrono,
      endChronology: endChrono,
    );
  }

  static DowntimeCategory _parseCategory(String category) {
    return DowntimeCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == category.toLowerCase(),
      orElse: () => DowntimeCategory.mechanicalBreakdown,
    );
  }
}
