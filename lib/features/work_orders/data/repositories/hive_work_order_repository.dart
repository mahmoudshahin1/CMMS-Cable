import '../../domain/repositories/work_order_repository.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/logic/work_order_state_machine.dart';
import '../../domain/logic/work_order_activity_logger.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../../core/errors/security_exceptions.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../datasources/work_order_local_data_source.dart';
import '../datasources/hive_work_order_local_data_source.dart';
import '../datasources/work_order_remote_data_source.dart';

/// Repository orchestrator for Work Orders.
///
/// Coordinates between [WorkOrderLocalDataSource] (Hive offline cache),
/// optional [WorkOrderRemoteDataSource] (Supabase backend),
/// and domain logic ([WorkOrderStateMachine], [WorkOrderActivityLogger]).
class HiveWorkOrderRepository implements WorkOrderRepository {
  final WorkOrderLocalDataSource _localDataSource;
  final WorkOrderRemoteDataSource? _remoteDataSource;

  HiveWorkOrderRepository({
    WorkOrderLocalDataSource? localDataSource,
    WorkOrderRemoteDataSource? remoteDataSource,
  })  : _localDataSource =
            localDataSource ?? HiveWorkOrderLocalDataSource(),
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async {
    return _localDataSource.getAllWorkOrders();
  }

  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async {
    return _localDataSource.getWorkOrderById(id);
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(
      WorkOrderStatus status) async {
    return _localDataSource.getWorkOrdersByStatus(status);
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(
      String technicianId) async {
    return _localDataSource.getWorkOrdersForTechnician(technicianId);
  }

  @override
  Future<WorkOrderModel> createWorkOrder(WorkOrderModel workOrder,
      {UserModel? caller}) async {
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
    final initialLog = WorkOrderActivityLogger.createLog(
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
      chronology: chrono,
    );

    final updated = workOrder.copyWith(
      chronology: chrono,
      activityLogs: [...workOrder.activityLogs, initialLog],
    );

    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
    return updated;
  }

  @override
  Future<void> updateWorkOrderStatus(
      String workOrderId, WorkOrderStatus status,
      {UserModel? caller}) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    WorkOrderStateMachine.validateTransition(wo.status, status);

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    if (wo.status != WorkOrderStatus.open &&
        wo.status != WorkOrderStatus.assigned) {
      throw IllegalStateTransitionException(
        fromStatus: wo.status.name,
        toStatus: WorkOrderStatus.assigned.name,
        message:
            'Cannot assign technician while work order is in [${wo.status.name}] status.',
      );
    }

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    if (wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
        message:
            'SECURITY ERROR: This ticket is assigned to a different technician.',
      );
    }

    WorkOrderStateMachine.validateTransition(
        wo.status, WorkOrderStatus.inProgress);

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }

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

    final updatedParts =
        List<SparePartModel>.from(wo.spareParts)..add(sparePart);
    final updated = wo.copyWith(
      spareParts: updatedParts,
      activityLogs: [...wo.activityLogs, log],
    );
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    if (caller != null &&
        wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }

    WorkOrderStateMachine.validateTransition(
        wo.status, WorkOrderStatus.completed);

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    WorkOrderStateMachine.validateTransition(
        wo.status, WorkOrderStatus.verified);

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
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

    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    WorkOrderStateMachine.validateTransition(
        wo.status, WorkOrderStatus.verifiedClosed);

    final log = WorkOrderActivityLogger.createLog(
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
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
  }
}
