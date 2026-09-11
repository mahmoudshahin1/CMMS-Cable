import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/work_order_repository.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/work_order_activity_log.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/errors/security_exceptions.dart';
import '../../../../core/chronology/event_chronology.dart';

class HiveWorkOrderRepository implements WorkOrderRepository {
  Box<WorkOrderModel> get _box =>
      Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);

  WorkOrderActivityLog _createLog({
    required String stepName,
    UserModel? caller,
    required String actionSummary,
    Map<String, dynamic>? details,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackRole,
  }) {
    final chrono = EventChronology.now();
    return WorkOrderActivityLog(
      id: const Uuid().v4(),
      stepName: stepName,
      performedByName: caller?.name ?? fallbackName ?? 'System Automated',
      performedByEmail:
          caller?.email ?? fallbackEmail ?? 'system@cableops.local',
      performedByRole:
          caller?.role.code ?? fallbackRole ?? 'SYSTEM',
      recordedAt: chrono.recordedAtUtc,
      actionSummary: actionSummary,
      details: details,
      chronology: chrono,
    );
  }

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async {
    return _box.values.toList();
  }

  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async {
    return _box.get(id);
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(
      WorkOrderStatus status) async {
    return _box.values.where((wo) => wo.status == status).toList();
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(
      String technicianId) async {
    return _box.values
        .where((wo) => wo.assignedToTechnicianId == technicianId)
        .toList();
  }

  @override
  Future<WorkOrderModel> createWorkOrder(WorkOrderModel workOrder,
      {UserModel? caller}) async {
    // Role check if caller is provided
    if (caller != null &&
        caller.role != UserRole.operator &&
        caller.role != UserRole.maintenanceSupervisor &&
        caller.role != UserRole.productionSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator or Supervisor',
        actualRole: caller.role.name,
      );
    }

    final chrono = workOrder.chronology ?? EventChronology.now();
    final initialLog = _createLog(
      stepName: 'REPORTED',
      caller: caller,
      actionSummary: 'Work order reported for machine ${workOrder.machineId}',
      details: {
        'machineId': workOrder.machineId,
        'priority': workOrder.priority.name,
        'type': workOrder.type.name,
      },
      fallbackName: 'Operator Desk',
      fallbackRole: 'OPERATOR',
    );

    final updated = workOrder.copyWith(
      chronology: chrono,
      activityLogs: [...workOrder.activityLogs, initialLog],
    );

    await _box.put(workOrder.id, updated);
    return updated;
  }

  @override
  Future<void> updateWorkOrderStatus(
      String workOrderId, WorkOrderStatus status,
      {UserModel? caller}) async {
    final wo = _box.get(workOrderId);
    if (wo == null) return;

    _validateTransition(wo.status, status);

    final log = _createLog(
      stepName: 'STATUS_CHANGED',
      caller: caller,
      actionSummary:
          'Work order transitioned from ${wo.status.name} to ${status.name}',
      details: {
        'fromStatus': wo.status.name,
        'toStatus': status.name,
      },
    );

    final updated = wo.copyWith(
      status: status,
      startedAt: status == WorkOrderStatus.inProgress && wo.startedAt == null
          ? DateTime.now()
          : wo.startedAt,
      completedAt: status == WorkOrderStatus.completed && wo.completedAt == null
          ? DateTime.now()
          : wo.completedAt,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> assignTechnician(
      String workOrderId, String technicianId, String supervisorId,
      {UserModel? caller}) async {
    if (caller != null && caller.role != UserRole.maintenanceSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Supervisors can assign technicians.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    // Must be in open or assigned status
    if (wo.status != WorkOrderStatus.open &&
        wo.status != WorkOrderStatus.assigned) {
      throw IllegalStateTransitionException(
        fromStatus: wo.status.name,
        toStatus: WorkOrderStatus.assigned.name,
        message:
            'Cannot assign technician while work order is in [${wo.status.name}] status.',
      );
    }

    final log = _createLog(
      stepName: 'ASSIGNED',
      caller: caller,
      actionSummary: 'Assigned to technician $technicianId',
      details: {
        'technicianId': technicianId,
        'supervisorId': supervisorId,
      },
      fallbackName: supervisorId,
      fallbackRole: 'MAINTENANCE_SUPERVISOR',
    );

    final updated = wo.copyWith(
      assignedToTechnicianId: technicianId,
      assignedBySupervisorId: supervisorId,
      status: WorkOrderStatus.assigned,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> startRepair(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can start repair work.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    // Cross-technician verification
    if (wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
        message:
            'SECURITY ERROR: This ticket is assigned to a different technician.',
      );
    }

    _validateTransition(wo.status, WorkOrderStatus.inProgress);

    final log = _createLog(
      stepName: 'REPAIR_STARTED',
      caller: caller,
      actionSummary: 'Field technician commenced repair operations',
      details: {
        'machineId': wo.machineId,
      },
    );

    final updated = wo.copyWith(
      status: WorkOrderStatus.inProgress,
      startedAt: wo.startedAt ?? DateTime.now(),
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> addSparePart(String workOrderId, SparePartModel sparePart,
      {UserModel? caller}) async {
    if (caller != null && caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can record spare parts.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }

    final log = _createLog(
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
    final updated = wo.copyWith(
      spareParts: updatedParts,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> completeWorkOrder(
    String workOrderId, {
    required String rootCause,
    required String actionsTaken,
    UserModel? caller,
  }) async {
    if (caller != null && caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Maintenance Technicians can complete repairs.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }

    _validateTransition(wo.status, WorkOrderStatus.completed);

    final log = _createLog(
      stepName: 'REPAIR_COMPLETED',
      caller: caller,
      actionSummary: 'Maintenance repair completed & root cause logged',
      details: {
        'rootCause': rootCause,
        'actionsTaken': actionsTaken,
        'totalSparePartsUsed': wo.spareParts.length,
      },
      fallbackName: 'Technician',
      fallbackRole: 'MAINTENANCE_TECH',
    );

    final updated = wo.copyWith(
      status: WorkOrderStatus.completed,
      completedAt: DateTime.now(),
      rootCause: rootCause,
      actionsTaken: actionsTaken,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> confirmTestRun(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.operator) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Line Operators can confirm field test runs.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    _validateTransition(wo.status, WorkOrderStatus.verified);

    final log = _createLog(
      stepName: 'TEST_RUN_PASSED',
      caller: caller,
      actionSummary: 'Operator executed field test run: Status PASSED',
      details: {
        'machineId': wo.machineId,
        'testRunResult': 'PASSED',
      },
    );

    final updated = wo.copyWith(
      status: WorkOrderStatus.verified,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  @override
  Future<void> approveAndClose(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.maintenanceSupervisor &&
        caller.role != UserRole.productionSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Supervisor',
        actualRole: caller.role.name,
        message:
            'SECURITY ERROR: Only Supervisors can approve and close work orders.',
      );
    }

    final wo = _box.get(workOrderId);
    if (wo == null) return;

    _validateTransition(wo.status, WorkOrderStatus.verifiedClosed);

    final log = _createLog(
      stepName: 'CLOSED',
      caller: caller,
      actionSummary:
          'Work order officially approved and closed by supervisor',
      details: {
        'supervisorId': caller.id,
      },
    );

    final updated = wo.copyWith(
      status: WorkOrderStatus.verifiedClosed,
      activityLogs: [...wo.activityLogs, log],
    );
    await _box.put(workOrderId, updated);
  }

  void _validateTransition(WorkOrderStatus current, WorkOrderStatus next) {
    if (current == next) return;

    bool valid = false;
    switch (current) {
      case WorkOrderStatus.open:
        valid = (next == WorkOrderStatus.assigned);
        break;
      case WorkOrderStatus.assigned:
        valid = (next == WorkOrderStatus.inProgress);
        break;
      case WorkOrderStatus.inProgress:
        valid = (next == WorkOrderStatus.completed ||
            next == WorkOrderStatus.pendingParts);
        break;
      case WorkOrderStatus.pendingParts:
        valid = (next == WorkOrderStatus.inProgress);
        break;
      case WorkOrderStatus.completed:
        valid = (next == WorkOrderStatus.verified);
        break;
      case WorkOrderStatus.verified:
        valid = (next == WorkOrderStatus.verifiedClosed);
        break;
      case WorkOrderStatus.verifiedClosed:
        valid = false; // Terminal state
        break;
    }

    if (!valid) {
      throw IllegalStateTransitionException(
        fromStatus: current.name,
        toStatus: next.name,
      );
    }
  }
}
