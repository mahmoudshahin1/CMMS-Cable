import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_activity_log.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/spare_part_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/cubit/work_order_state.dart';
import 'package:orning_and_evening_remembrances/core/errors/security_exceptions.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/core/chronology/event_chronology.dart';

class InMemorySecureWorkOrderRepository implements WorkOrderRepository {
  final Map<String, WorkOrderModel> _storage = {};

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async =>
      _storage.values.toList();

  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async => _storage[id];

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(
          WorkOrderStatus status) async =>
      _storage.values.where((w) => w.status == status).toList();

  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(
          String technicianId) async =>
      _storage.values
          .where((w) => w.assignedToTechnicianId == technicianId)
          .toList();

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
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
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
  Future<WorkOrderModel> createWorkOrder(WorkOrderModel workOrder,
      {UserModel? caller}) async {
    final log = _createLog(
      stepName: 'REPORTED',
      caller: caller,
      actionSummary: 'Work order created',
      fallbackName: 'Operator',
      fallbackRole: 'OPERATOR',
    );
    final updated = workOrder.copyWith(
      activityLogs: [...workOrder.activityLogs, log],
    );
    _storage[workOrder.id] = updated;
    return updated;
  }

  @override
  Future<void> updateWorkOrderStatus(String workOrderId, WorkOrderStatus status,
      {UserModel? caller}) async {
    final wo = _storage[workOrderId];
    if (wo == null) return;
    _validateTransition(wo.status, status);
    final log = _createLog(
      stepName: 'STATUS_CHANGED',
      caller: caller,
      actionSummary: 'Status updated to ${status.name}',
    );
    _storage[workOrderId] = wo.copyWith(
      status: status,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  @override
  Future<void> assignTechnician(
      String workOrderId, String technicianId, String supervisorId,
      {UserModel? caller}) async {
    if (caller != null && caller.role != UserRole.maintenanceSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Supervisor',
        actualRole: caller.role.name,
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    if (wo.status != WorkOrderStatus.open &&
        wo.status != WorkOrderStatus.assigned) {
      throw IllegalStateTransitionException(
        fromStatus: wo.status.name,
        toStatus: WorkOrderStatus.assigned.name,
      );
    }
    final log = _createLog(
      stepName: 'ASSIGNED',
      caller: caller,
      actionSummary: 'Assigned to technician $technicianId',
      fallbackName: supervisorId,
      fallbackRole: 'MAINTENANCE_SUPERVISOR',
    );
    _storage[workOrderId] = wo.copyWith(
      assignedToTechnicianId: technicianId,
      assignedBySupervisorId: supervisorId,
      status: WorkOrderStatus.assigned,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  @override
  Future<void> startRepair(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    if (wo.assignedToTechnicianId != null &&
        wo.assignedToTechnicianId != caller.id) {
      throw UnassignedTechnicianException(
        expectedTechId: wo.assignedToTechnicianId!,
        actualTechId: caller.id,
      );
    }
    _validateTransition(wo.status, WorkOrderStatus.inProgress);
    final log = _createLog(
      stepName: 'REPAIR_STARTED',
      caller: caller,
      actionSummary: 'Repair work started',
    );
    _storage[workOrderId] = wo.copyWith(
      status: WorkOrderStatus.inProgress,
      startedAt: DateTime.now(),
      activityLogs: [...wo.activityLogs, log],
    );
  }

  @override
  Future<void> addSparePart(String workOrderId, SparePartModel sparePart,
      {UserModel? caller}) async {
    if (caller != null && caller.role != UserRole.maintenanceTech) {
      throw UnauthorizedRoleException(
        requiredRole: 'Maintenance Technician',
        actualRole: caller.role.name,
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    final log = _createLog(
      stepName: 'SPARE_PART_ADDED',
      caller: caller,
      actionSummary: 'Spare part added: ${sparePart.name}',
    );
    final parts = List<SparePartModel>.from(wo.spareParts)..add(sparePart);
    _storage[workOrderId] = wo.copyWith(
      spareParts: parts,
      activityLogs: [...wo.activityLogs, log],
    );
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
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    _validateTransition(wo.status, WorkOrderStatus.completed);
    final log = _createLog(
      stepName: 'REPAIR_COMPLETED',
      caller: caller,
      actionSummary: 'Repair completed with root cause: $rootCause',
    );
    _storage[workOrderId] = wo.copyWith(
      status: WorkOrderStatus.completed,
      completedAt: DateTime.now(),
      rootCause: rootCause,
      actionsTaken: actionsTaken,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  @override
  Future<void> confirmTestRun(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.operator) {
      throw UnauthorizedRoleException(
        requiredRole: 'Operator',
        actualRole: caller.role.name,
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    _validateTransition(wo.status, WorkOrderStatus.verified);
    final log = _createLog(
      stepName: 'TEST_RUN_PASSED',
      caller: caller,
      actionSummary: 'Test run passed',
    );
    _storage[workOrderId] = wo.copyWith(
      status: WorkOrderStatus.verified,
      activityLogs: [...wo.activityLogs, log],
    );
  }

  @override
  Future<void> approveAndClose(String workOrderId,
      {required UserModel caller}) async {
    if (caller.role != UserRole.maintenanceSupervisor &&
        caller.role != UserRole.productionSupervisor) {
      throw UnauthorizedRoleException(
        requiredRole: 'Supervisor',
        actualRole: caller.role.name,
      );
    }
    final wo = _storage[workOrderId];
    if (wo == null) return;
    _validateTransition(wo.status, WorkOrderStatus.verifiedClosed);
    final log = _createLog(
      stepName: 'CLOSED',
      caller: caller,
      actionSummary: 'Work order approved and closed',
    );
    _storage[workOrderId] = wo.copyWith(
      status: WorkOrderStatus.verifiedClosed,
      activityLogs: [...wo.activityLogs, log],
    );
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
        valid = false;
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

void main() {
  group('3-Tier RBAC & Business Logic Defense-in-Depth Tests', () {
    late InMemorySecureWorkOrderRepository repo;
    late WorkOrderCubit cubit;

    final initialOrder = WorkOrderModel(
      id: 'wo-test-01',
      title: 'Extruder Barrel Heater Malfunction',
      description: 'Heater zone 3 is down on EX01',
      machineId: 'EX01',
      type: WorkOrderType.corrective,
      status: WorkOrderStatus.open,
      priority: Priority.high,
      createdAt: DateTime.now(),
    );

    setUp(() async {
      repo = InMemorySecureWorkOrderRepository();
      await repo.createWorkOrder(initialOrder);
      cubit = WorkOrderCubit(repo);
    });

    tearDown(() {
      cubit.close();
    });

    test('SECURITY LAYER 2 & 3: Operator attempting startRepair() is strictly rejected', () async {
      // Operator attempts to bypass UI and call startRepair directly
      await cubit.startRepair('wo-test-01', caller: MockUsers.operatorUser);

      // Business logic caught UnauthorizedRoleException and emitted WorkOrderError
      expect(cubit.state, isA<WorkOrderError>());
      final errorState = cubit.state as WorkOrderError;
      expect(errorState.message, contains('UNAUTHORIZED'));

      // Verify ticket state remains untouched in data layer
      final wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.open));
    });

    test('SECURITY LAYER 2 & 3: Cross-Technician attempt is rejected (Tech B cannot start Tech A ticket)', () async {
      // Supervisor assigns ticket to Electrical Tech (Tariq)
      await repo.assignTechnician(
        'wo-test-01',
        MockUsers.electricalTech.id,
        MockUsers.maintenanceSupervisor.id,
        caller: MockUsers.maintenanceSupervisor,
      );

      // Mechanical Tech (Samir) attempts to start Tariq\'s ticket
      await cubit.startRepair('wo-test-01', caller: MockUsers.mechanicalTech);

      expect(cubit.state, isA<WorkOrderError>());
      final errorState = cubit.state as WorkOrderError;
      expect(errorState.message, contains('UNAUTHORIZED'));

      // Verify ticket is still in assigned state
      final wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.assigned));
    });

    test('STATE MACHINE GUARD: Illegal state skip is rejected (Cannot jump from open to closed)', () async {
      expect(
        () => repo.updateWorkOrderStatus(
          'wo-test-01',
          WorkOrderStatus.verifiedClosed,
        ),
        throwsA(isA<IllegalStateTransitionException>()),
      );
    });

    test('FULL VERIFIED HANDSHAKE: Strict sequential authorization succeeds end-to-end with non-tamperable audit logs', () async {
      // Step 2: Supervisor assigns technician
      await cubit.assignTechnician(
        'wo-test-01',
        MockUsers.electricalTech.id,
        MockUsers.maintenanceSupervisor.id,
        caller: MockUsers.maintenanceSupervisor,
      );
      var wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.assigned));
      expect(wo?.assignedToTechnicianId, equals(MockUsers.electricalTech.id));

      // Step 3: Assigned technician starts repair
      await cubit.startRepair('wo-test-01', caller: MockUsers.electricalTech);
      wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.inProgress));

      // Step 3: Technician completes repair
      await cubit.completeWorkOrder(
        'wo-test-01',
        rootCause: 'Heating element burnt out',
        actionsTaken: 'Replaced element and tested PID loop',
        caller: MockUsers.electricalTech,
      );
      wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.completed));

      // Step 4: Operator confirms test run
      await cubit.confirmTestRun('wo-test-01', caller: MockUsers.operatorUser);
      wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.verified));

      // Step 5: Supervisor approves and closes ticket
      await cubit.approveAndClose(
        'wo-test-01',
        caller: MockUsers.maintenanceSupervisor,
      );
      wo = await repo.getWorkOrderById('wo-test-01');
      expect(wo?.status, equals(WorkOrderStatus.verifiedClosed));

      // VERIFY AUDIT & ACTIVITY LOG TRAIL
      expect(wo?.activityLogs, isNotNull);
      expect(wo?.activityLogs.length, equals(6));

      // 1. Initial Creation
      expect(wo!.activityLogs[0].stepName, equals('REPORTED'));
      expect(wo.activityLogs[0].performedByRole, equals('OPERATOR'));

      // 2. Supervisor Assignment
      expect(wo.activityLogs[1].stepName, equals('ASSIGNED'));
      expect(wo.activityLogs[1].performedByEmail, equals(MockUsers.maintenanceSupervisor.email));
      expect(wo.activityLogs[1].performedByRole, equals('MAINTENANCE_SUPERVISOR'));

      // 3. Technician Starts Repair
      expect(wo.activityLogs[2].stepName, equals('REPAIR_STARTED'));
      expect(wo.activityLogs[2].performedByName, equals(MockUsers.electricalTech.name));
      expect(wo.activityLogs[2].performedByEmail, equals(MockUsers.electricalTech.email));
      expect(wo.activityLogs[2].performedByRole, equals('MAINTENANCE_TECH'));

      // 4. Technician Completes Repair
      expect(wo.activityLogs[3].stepName, equals('REPAIR_COMPLETED'));
      expect(wo.activityLogs[3].performedByEmail, equals(MockUsers.electricalTech.email));
      expect(wo.activityLogs[3].actionSummary, contains('Heating element burnt out'));

      // 5. Operator Confirms Test Run
      expect(wo.activityLogs[4].stepName, equals('TEST_RUN_PASSED'));
      expect(wo.activityLogs[4].performedByName, equals(MockUsers.operatorUser.name));
      expect(wo.activityLogs[4].performedByEmail, equals(MockUsers.operatorUser.email));
      expect(wo.activityLogs[4].performedByRole, equals('OPERATOR'));

      // 6. Supervisor Closes Ticket
      expect(wo.activityLogs[5].stepName, equals('CLOSED'));
      expect(wo.activityLogs[5].performedByName, equals(MockUsers.maintenanceSupervisor.name));
      expect(wo.activityLogs[5].performedByRole, equals('MAINTENANCE_SUPERVISOR'));

      // All logs must contain valid recordedAt timestamps and shift-aware chronology
      for (final log in wo.activityLogs) {
        expect(log.recordedAt.isBefore(DateTime.now().toUtc().add(const Duration(seconds: 1))), isTrue);
        expect(log.actionSummary, isNotEmpty);
        expect(log.chronology, isNotNull);
        expect(log.chronology!.activeShift, isNotNull);
        expect(log.chronology!.plantTimeFormatted, isNotEmpty);
        expect(log.chronology!.productionDateFormatted, isNotEmpty);
      }
    });
  });
}
