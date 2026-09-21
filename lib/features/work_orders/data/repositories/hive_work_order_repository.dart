import '../../domain/repositories/work_order_repository.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/logic/work_order_state_machine.dart';
import '../../domain/logic/work_order_activity_logger.dart';
import '../../domain/logic/work_order_security_guard.dart';
import '../../domain/logic/work_order_handshake_mutator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/auth/user_directory_helper.dart';
import '../datasources/work_order_local_data_source.dart';
import '../datasources/hive_work_order_local_data_source.dart';
import '../datasources/work_order_remote_data_source.dart';

import '../../../../core/sync/outbox/outbox_command.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';
import '../datasources/work_order_outbox_factory.dart';

/// Repository orchestrator for Work Orders.
class HiveWorkOrderRepository implements WorkOrderRepository {
  final WorkOrderLocalDataSource _localDataSource;
  final WorkOrderRemoteDataSource? _remoteDataSource;
  final OutboxSyncEngine? _syncEngine;

  HiveWorkOrderRepository({
    WorkOrderLocalDataSource? localDataSource,
    WorkOrderRemoteDataSource? remoteDataSource,
    OutboxSyncEngine? syncEngine,
  })  : _localDataSource =
            localDataSource ?? HiveWorkOrderLocalDataSource(),
        _remoteDataSource = remoteDataSource,
        _syncEngine = syncEngine;

  Future<void> _persistAndSync(
    WorkOrderModel updated, [
    OutboxCommand? command,
  ]) async {
    await _localDataSource.cacheWorkOrder(updated);
    _remoteDataSource?.syncWorkOrder(updated);
    if (command != null) {
      _syncEngine?.enqueueAndTrigger(command);
    }
  }

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
  Future<WorkOrderModel> createWorkOrder(
    WorkOrderModel workOrder, {
    UserModel? caller,
  }) async {
    final effectiveCaller = caller ?? UserDirectoryHelper.currentUser;
    WorkOrderSecurityGuard.validateCreate(effectiveCaller);

    final chrono = workOrder.chronology ?? EventChronology.now();
    final initialLog = WorkOrderActivityLogger.createLog(
      stepName: 'REPORTED',
      caller: effectiveCaller,
      actionSummary: 'Work order reported for machine ${workOrder.machineId}',
      details: {
        'machineId': workOrder.machineId,
        'priority': workOrder.priority.name,
        'type': workOrder.type.name,
      },
      fallbackName: effectiveCaller?.name ?? 'Operator Desk',
      fallbackRole: effectiveCaller?.role.code ?? 'OPERATOR',
      chronology: chrono,
    );

    final updated = workOrder.copyWith(
      chronology: chrono,
      activityLogs: [...workOrder.activityLogs, initialLog],
    );

    await _persistAndSync(updated, WorkOrderOutboxFactory.create(updated));
    return updated;
  }

  @override
  Future<void> updateWorkOrderStatus(
    String workOrderId,
    WorkOrderStatus status, {
    UserModel? caller,
  }) async {
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
    await _persistAndSync(updated);
  }

  @override
  Future<void> assignTechnician(
    String workOrderId,
    String technicianId,
    String supervisorId, {
    UserModel? caller,
    String? technicianName,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyAssign(
      wo,
      technicianId,
      supervisorId,
      caller,
      technicianName: technicianName,
    );
    await _persistAndSync(
      updated,
      WorkOrderOutboxFactory.assign(updated, technicianId),
    );
  }

  @override
  Future<void> startRepair(
    String workOrderId, {
    required UserModel caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyStartRepair(wo, caller);
    await _persistAndSync(updated, WorkOrderOutboxFactory.start(updated));
  }

  @override
  Future<void> addSparePart(
    String workOrderId,
    SparePartModel sparePart, {
    UserModel? caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyAddSparePart(
      wo,
      sparePart,
      caller,
    );
    await _persistAndSync(
      updated,
      WorkOrderOutboxFactory.addPart(updated, sparePart),
    );
  }

  @override
  Future<void> completeWorkOrder(
    String workOrderId, {
    required String rootCause,
    required String actionsTaken,
    UserModel? caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyComplete(
      wo,
      rootCause: rootCause,
      actionsTaken: actionsTaken,
      caller: caller,
    );
    await _persistAndSync(
      updated,
      WorkOrderOutboxFactory.complete(
        updated,
        rootCause: rootCause,
        actionsTaken: actionsTaken,
      ),
    );
  }

  @override
  Future<void> confirmTestRun(
    String workOrderId, {
    required UserModel caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyConfirmTestRun(wo, caller);
    await _persistAndSync(
      updated,
      WorkOrderOutboxFactory.confirmTestRun(updated),
    );
  }

  @override
  Future<void> approveAndClose(
    String workOrderId, {
    required UserModel caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyApproveAndClose(wo, caller);
    await _persistAndSync(updated, WorkOrderOutboxFactory.close(updated));
  }
}
