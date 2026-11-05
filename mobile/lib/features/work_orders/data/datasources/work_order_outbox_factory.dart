import 'package:uuid/uuid.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/models/repair_step_model.dart';
import '../../../../core/sync/outbox/outbox_command.dart';

/// Factory producing strongly-typed [OutboxCommand]s for work order mutations.
class WorkOrderOutboxFactory {
  static const _uuid = Uuid();

  static OutboxCommand create(
    WorkOrderModel wo, {
    String? voiceNoteUrl,
  }) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'create_work_order',
      aggregateId: wo.id,
      payload: {
        'title': wo.title,
        'description': wo.description,
        'machine_id': wo.machineId,
        'type': wo.type.name,
        'priority': wo.priority.name,
        if (voiceNoteUrl != null || wo.voiceNoteUrl != null) ...{
          'voice_note_url': voiceNoteUrl ?? wo.voiceNoteUrl,
          'p_voice_note_url': voiceNoteUrl ?? wo.voiceNoteUrl,
        }
      },
      occurredAt: wo.createdAt,
      expectedVersion: 1,
    );
  }

  static OutboxCommand assign(
    WorkOrderModel wo,
    String technicianId, {
    int? expectedVersion,
  }) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'assign_work_order',
      aggregateId: wo.id,
      payload: {'technician_id': technicianId},
      occurredAt: DateTime.now(),
      expectedVersion: expectedVersion ?? wo.version,
    );
  }

  static OutboxCommand start(WorkOrderModel wo, {int? expectedVersion}) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'start_work_order',
      aggregateId: wo.id,
      payload: {},
      occurredAt: DateTime.now(),
      expectedVersion: expectedVersion ?? wo.version,
    );
  }

  static OutboxCommand addPart(WorkOrderModel wo, SparePartModel part) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'add_work_order_part',
      aggregateId: wo.id,
      payload: {
        'part_id': part.id.isNotEmpty ? part.id : _uuid.v4(),
        'part_code': part.partNumber,
        'part_name': part.name,
        'quantity': part.quantityUsed,
        'unit_cost': part.unitCost ?? 0.0,
      },
      occurredAt: DateTime.now(),
    );
  }

  static OutboxCommand complete(
    WorkOrderModel wo, {
    required String rootCause,
    required String actionsTaken,
    List<RepairStepModel>? repairSteps,
    String? repairVoiceUrl,
    int? expectedVersion,
  }) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'complete_work_order',
      aggregateId: wo.id,
      payload: {
        'root_cause': rootCause,
        'actions_taken': actionsTaken,
        'repair_steps': (repairSteps ?? wo.repairSteps).map((e) => e.toJson()).toList(),
        'p_repair_steps': (repairSteps ?? wo.repairSteps).map((e) => e.toJson()).toList(),
        if (repairVoiceUrl != null || wo.repairVoiceUrl != null) ...{
          'repair_voice_url': repairVoiceUrl ?? wo.repairVoiceUrl,
          'p_repair_voice_url': repairVoiceUrl ?? wo.repairVoiceUrl,
        }
      },
      occurredAt: DateTime.now(),
      expectedVersion: expectedVersion ?? wo.version,
    );
  }

  static OutboxCommand confirmTestRun(
    WorkOrderModel wo, {
    String outcome = 'fixed',
    String? comments,
    int? confirmedDowntimeMinutes,
    int? expectedVersion,
  }) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'confirm_test_run',
      aggregateId: wo.id,
      payload: {
        'outcome': outcome,
        if (comments != null) 'comments': comments,
        if (confirmedDowntimeMinutes != null)
          'confirmed_downtime_minutes': confirmedDowntimeMinutes,
      },
      occurredAt: DateTime.now(),
      expectedVersion: expectedVersion ?? wo.version,
    );
  }

  static OutboxCommand close(WorkOrderModel wo, {int? expectedVersion}) {
    return OutboxCommand(
      commandId: _uuid.v4(),
      commandType: 'close_work_order',
      aggregateId: wo.id,
      payload: {},
      occurredAt: DateTime.now(),
      expectedVersion: expectedVersion ?? wo.version,
    );
  }
}
