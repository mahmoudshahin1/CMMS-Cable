import '../../domain/repositories/work_order_repository.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/models/repair_step_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/logic/work_order_state_machine.dart';
import '../../domain/logic/work_order_activity_logger.dart';
import '../../domain/logic/work_order_security_guard.dart';
import '../../domain/logic/work_order_handshake_mutator.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../../core/chronology/event_chronology.dart';
import '../../../../core/auth/user_directory_helper.dart';
import '../../../../core/sync/outbox/outbox_command.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';
import '../datasources/work_order_local_data_source.dart';
import '../datasources/hive_work_order_local_data_source.dart';
import '../datasources/work_order_remote_data_source.dart';
import '../datasources/work_order_outbox_factory.dart';
import 'work_order_repository_sync_helper.dart';

/// Repository orchestrator for Work Orders.
class HiveWorkOrderRepository implements WorkOrderRepository {
  final WorkOrderLocalDataSource _localDataSource;
  final WorkOrderRemoteDataSource? _remoteDataSource;
  final OutboxSyncEngine? _syncEngine;

  HiveWorkOrderRepository({
    WorkOrderLocalDataSource? localDataSource,
    WorkOrderRemoteDataSource? remoteDataSource,
    OutboxSyncEngine? syncEngine,
  })  : _localDataSource = localDataSource ?? HiveWorkOrderLocalDataSource(),
        _remoteDataSource = remoteDataSource,
        _syncEngine = syncEngine;

  Future<void> _save(WorkOrderModel updated, [OutboxCommand? cmd]) =>
      WorkOrderRepositorySyncHelper.persistAndSync(
        updated: updated,
        localDataSource: _localDataSource,
        remoteDataSource: _remoteDataSource,
        syncEngine: _syncEngine,
        command: cmd,
      );

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() =>
      _localDataSource.getAllWorkOrders();

  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) =>
      _localDataSource.getWorkOrderById(id);

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(WorkOrderStatus status) =>
      _localDataSource.getWorkOrdersByStatus(status);

  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(String techId) =>
      _localDataSource.getWorkOrdersForTechnician(techId);

  @override
  Future<WorkOrderModel> createWorkOrder(
    WorkOrderModel workOrder, {
    UserModel? caller,
  }) async {
    final effectiveCaller = caller ?? UserDirectoryHelper.currentUser;
    final machine = WorkOrderRepositorySyncHelper.findMachine(workOrder.machineId);
    WorkOrderSecurityGuard.validateCreate(effectiveCaller, machine);

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

    await _save(updated, WorkOrderOutboxFactory.create(updated));
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
      actionSummary: 'Work order transitioned from ${wo.status.name} to ${status.name}',
      details: {'fromStatus': wo.status.name, 'toStatus': status.name},
    );

    final updated = wo.copyWith(
      status: status,
      startedAt: status == WorkOrderStatus.inProgress && wo.startedAt == null ? DateTime.now() : wo.startedAt,
      completedAt: status == WorkOrderStatus.completed && wo.completedAt == null ? DateTime.now() : wo.completedAt,
      activityLogs: [...wo.activityLogs, log],
    );
    await _save(updated);
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
    await _save(updated, WorkOrderOutboxFactory.assign(updated, technicianId));
  }

  @override
  Future<void> startRepair(
    String workOrderId, {
    required UserModel caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyStartRepair(wo, caller);
    await _save(updated, WorkOrderOutboxFactory.start(updated));
  }

  @override
  Future<void> addSparePart(
    String workOrderId,
    SparePartModel sparePart, {
    UserModel? caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyAddSparePart(wo, sparePart, caller);
    await _save(updated, WorkOrderOutboxFactory.addPart(updated, sparePart));
  }

  @override
  Future<void> completeWorkOrder(
    String workOrderId, {
    required String rootCause,
    required String actionsTaken,
    List<RepairStepModel>? repairSteps,
    String? repairVoiceUrl,
    UserModel? caller,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final updated = WorkOrderHandshakeMutator.applyComplete(
      wo,
      rootCause: rootCause,
      actionsTaken: actionsTaken,
      repairSteps: repairSteps,
      repairVoiceUrl: repairVoiceUrl,
      caller: caller,
    );
    await _save(
      updated,
      WorkOrderOutboxFactory.complete(
        updated,
        rootCause: rootCause,
        actionsTaken: actionsTaken,
        repairSteps: repairSteps,
        repairVoiceUrl: repairVoiceUrl,
      ),
    );
  }

  @override
  Future<void> confirmTestRun(
    String workOrderId, {
    required UserModel caller,
    String outcome = 'fixed',
    String? comments,
    int? confirmedDowntimeMinutes,
  }) async {
    final wo = await _localDataSource.getWorkOrderById(workOrderId);
    if (wo == null) return;

    final machine = WorkOrderRepositorySyncHelper.findMachine(wo.machineId);
    final updated = WorkOrderHandshakeMutator.applyConfirmTestRun(
      wo,
      caller,
      outcome: outcome,
      comments: comments,
      confirmedDowntimeMinutes: confirmedDowntimeMinutes,
      machine: machine,
    );
    await _save(
      updated,
      WorkOrderOutboxFactory.confirmTestRun(
        updated,
        outcome: outcome,
        comments: comments,
        confirmedDowntimeMinutes: confirmedDowntimeMinutes,
      ),
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
    await _save(updated, WorkOrderOutboxFactory.close(updated));
  }
}
