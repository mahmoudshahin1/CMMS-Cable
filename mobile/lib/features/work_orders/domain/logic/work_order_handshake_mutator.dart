import '../../../../core/auth/user_directory_helper.dart';
import '../../../../core/errors/security_exceptions.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../models/work_order_model.dart';
import '../models/spare_part_model.dart';
import '../models/repair_step_model.dart';
import '../enums/work_order_status.dart';
import 'work_order_state_machine.dart';
import 'work_order_activity_logger.dart';
import 'work_order_security_guard.dart';

/// Pure domain mutator applying the 5-step industrial maintenance
/// handshake transitions, RBAC validations, and audit activity logging.
class WorkOrderHandshakeMutator {
  static WorkOrderModel applyAssign(
    WorkOrderModel wo,
    String technicianId,
    String supervisorId,
    UserModel? caller, {
    String? technicianName,
  }) {
    WorkOrderSecurityGuard.validateAssign(caller);

    if (wo.status != WorkOrderStatus.open &&
        wo.status != WorkOrderStatus.assigned) {
      throw IllegalStateTransitionException(
        fromStatus: wo.status.name,
        toStatus: WorkOrderStatus.assigned.name,
        message:
            'Cannot assign technician while work order is in [${wo.status.name}] status.',
      );
    }

    final resolvedTech = (technicianName != null && technicianName.trim().isNotEmpty)
        ? technicianName
        : (UserDirectoryHelper.resolveName(technicianId) ?? technicianId);

    final resolvedSup = (caller != null && caller.name.trim().isNotEmpty)
        ? caller.name
        : (UserDirectoryHelper.resolveName(supervisorId) ?? supervisorId);

    final log = WorkOrderActivityLogger.createLog(
      stepName: 'ASSIGNED',
      caller: caller,
      actionSummary: 'Assigned to technician $resolvedTech',
      details: {
        'technician': resolvedTech,
        'supervisor': resolvedSup,
        'technicianId': technicianId,
        'supervisorId': supervisorId,
      },
      fallbackName: resolvedSup,
      fallbackRole: 'MAINTENANCE_SUPERVISOR',
    );

    return wo.copyWith(
      assignedToTechnicianId: technicianId,
      assignedBySupervisorId: supervisorId,
      status: WorkOrderStatus.assigned,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  static WorkOrderModel applyStartRepair(
    WorkOrderModel wo,
    UserModel caller,
  ) {
    WorkOrderSecurityGuard.validateStartRepair(caller, wo);
    WorkOrderStateMachine.validateTransition(
      wo.status,
      WorkOrderStatus.inProgress,
    );

    final log = WorkOrderActivityLogger.createLog(
      stepName: 'REPAIR_STARTED',
      caller: caller,
      actionSummary: 'Field technician commenced repair operations',
      details: {'machineId': wo.machineId},
    );

    return wo.copyWith(
      status: WorkOrderStatus.inProgress,
      startedAt: wo.startedAt ?? DateTime.now(),
      activityLogs: [...wo.activityLogs, log],
    );
  }

  static WorkOrderModel applyAddSparePart(
    WorkOrderModel wo,
    SparePartModel sparePart,
    UserModel? caller,
  ) {
    WorkOrderSecurityGuard.validateAddSparePart(caller, wo);

    final log = WorkOrderActivityLogger.createLog(
      stepName: 'SPARE_PART_ADDED',
      caller: caller,
      actionSummary:
          'Installed spare part: ${sparePart.name} (x${sparePart.quantityUsed})',
      details: {
        'partNumber': sparePart.partNumber,
        'name': sparePart.name,
        'quantity': sparePart.quantityUsed,
        'unitCost': sparePart.unitCost,
      },
      fallbackName: 'Technician',
      fallbackRole: 'MAINTENANCE_TECH',
    );

    final updatedParts = List<SparePartModel>.from(wo.spareParts)
      ..add(sparePart);
    return wo.copyWith(
      spareParts: updatedParts,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  static WorkOrderModel applyComplete(
    WorkOrderModel wo, {
    required String rootCause,
    required String actionsTaken,
    List<RepairStepModel>? repairSteps,
    String? repairVoiceUrl,
    UserModel? caller,
  }) {
    WorkOrderSecurityGuard.validateComplete(caller, wo);
    WorkOrderStateMachine.validateTransition(
      wo.status,
      WorkOrderStatus.completed,
    );

    final resolvedSteps = repairSteps ?? wo.repairSteps;
    final derivedActions = actionsTaken.trim().isNotEmpty
        ? actionsTaken
        : (resolvedSteps.isNotEmpty
            ? resolvedSteps.map((s) => s.description).join('; ')
            : 'Field repair completed');

    final log = WorkOrderActivityLogger.createLog(
      stepName: 'REPAIR_COMPLETED',
      caller: caller,
      actionSummary: 'Maintenance repair completed & root cause logged',
      details: {
        'rootCause': rootCause,
        'actionsTaken': derivedActions,
        'totalSparePartsUsed': wo.spareParts.length,
        'stepsCount': resolvedSteps.length,
      },
      fallbackName: 'Technician',
      fallbackRole: 'MAINTENANCE_TECH',
    );

    return wo.copyWith(
      status: WorkOrderStatus.completed,
      completedAt: DateTime.now(),
      rootCause: rootCause,
      actionsTaken: derivedActions,
      repairSteps: resolvedSteps,
      repairVoiceUrl: repairVoiceUrl ?? wo.repairVoiceUrl,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  static WorkOrderModel applyConfirmTestRun(
    WorkOrderModel wo,
    UserModel caller, {
    String outcome = 'fixed',
    String? comments,
    int? confirmedDowntimeMinutes,
    MachineModel? machine,
  }) {
    if (outcome != 'fixed' && (comments == null || comments.trim().isEmpty)) {
      throw ArgumentError(
        'Rejection notes are required when outcome is "$outcome".',
      );
    }
    WorkOrderSecurityGuard.validateConfirmTestRun(caller, machine);
    final targetStatus = outcome == 'fixed'
        ? WorkOrderStatus.verified
        : WorkOrderStatus.inProgress;
    WorkOrderStateMachine.validateTransition(
      wo.status,
      targetStatus,
    );

    final isFixed = outcome == 'fixed';
    final log = WorkOrderActivityLogger.createLog(
      stepName: isFixed ? 'TEST_RUN_PASSED' : 'TEST_RUN_REJECTED',
      caller: caller,
      actionSummary: isFixed
          ? 'Operator executed field test run: Status PASSED'
          : 'Test run bounced back ($outcome): ${comments ?? ''}',
      details: {
        'machineId': wo.machineId,
        'testRunResult': isFixed ? 'PASSED' : 'BOUNCED_BACK',
        'outcome': outcome,
        if (comments != null) 'comments': comments,
        if (confirmedDowntimeMinutes != null)
          'confirmedDowntimeMinutes': confirmedDowntimeMinutes,
      },
    );

    final checkEntry = <String, dynamic>{
      'at': DateTime.now().toIso8601String(),
      'by': caller.id,
      'outcome': outcome,
      if (comments != null) 'notes': comments,
      if (confirmedDowntimeMinutes != null)
        'confirmed_downtime_minutes': confirmedDowntimeMinutes,
    };

    return wo.copyWith(
      status: targetStatus,
      activityLogs: [...wo.activityLogs, log],
      checks: [...wo.checks, checkEntry],
    );
  }

  static WorkOrderModel applyApproveAndClose(
    WorkOrderModel wo,
    UserModel caller,
  ) {
    WorkOrderSecurityGuard.validateApproveAndClose(caller);
    WorkOrderStateMachine.validateTransition(
      wo.status,
      WorkOrderStatus.verifiedClosed,
    );

    final log = WorkOrderActivityLogger.createLog(
      stepName: 'CLOSED',
      caller: caller,
      actionSummary:
          'Work order officially approved and closed by supervisor',
      details: {'supervisorId': caller.id},
    );

    return wo.copyWith(
      status: WorkOrderStatus.verifiedClosed,
      activityLogs: [...wo.activityLogs, log],
    );
  }
}
