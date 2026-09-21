import 'package:uuid/uuid.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../../../core/sync/outbox/outbox_command.dart';

/// Factory generating typed [OutboxCommand]s for downtime log mutations.
class DowntimeOutboxFactory {
  static const _uuid = Uuid();

  static OutboxCommand create(DowntimeLogModel log) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'create_downtime_log',
      aggregateId: log.id,
      payload: {
        'machine_id': log.machineId,
        'category': log.category.name,
        'reason': log.reason,
        'is_maintenance_requested': log.isMaintenanceRequested,
        'work_order_id': log.workOrderId,
        'comments': log.comments,
        'start_chronology': log.startChronology?.toJson(),
        'shift_minutes': {
          for (final entry in log.downtimeMinutesPerShift.entries)
            entry.key.name: entry.value,
        },
      },
      occurredAt: log.startTime,
    );
  }

  static OutboxCommand close(DowntimeLogModel log) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'close_downtime_log',
      aggregateId: log.id,
      payload: {
        'end_chronology': log.endChronology?.toJson(),
        'shift_minutes': {
          for (final entry in log.downtimeMinutesPerShift.entries)
            entry.key.name: entry.value,
        },
      },
      occurredAt: log.endTime ?? DateTime.now(),
    );
  }
}
