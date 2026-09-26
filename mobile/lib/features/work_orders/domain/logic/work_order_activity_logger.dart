import 'package:uuid/uuid.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../models/work_order_activity_log.dart';

/// Factory helper for creating immutable audit trail activity logs.
class WorkOrderActivityLogger {
  const WorkOrderActivityLogger._();

  static const _uuid = Uuid();

  /// Builds a tamper-evident, timestamped activity log entry.
  static WorkOrderActivityLog createLog({
    required String stepName,
    UserModel? caller,
    required String actionSummary,
    Map<String, dynamic>? details,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackRole,
    EventChronology? chronology,
  }) {
    final chrono = chronology ?? EventChronology.now();
    return WorkOrderActivityLog(
      id: _uuid.v4(),
      stepName: stepName,
      performedByName: caller?.name ?? fallbackName ?? 'System Automated',
      performedByEmail:
          caller?.email ?? fallbackEmail ?? 'system@cableops.local',
      performedByRole: caller?.role.code ?? fallbackRole ?? 'SYSTEM',
      recordedAt: chrono.recordedAtUtc,
      actionSummary: actionSummary,
      details: details,
      chronology: chrono,
    );
  }
}
