import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/errors/security_exceptions.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_outbox_factory.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/confirm_test_run_rpc_params.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_mapper.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_handshake_mutator.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_security_guard.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_state_machine.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';

void main() {
  final drawingMachine = MachineModel(
    id: 'DR01',
    code: 'DR01',
    name: 'Drawing Line 01',
    subCategory: 'Drawing',
    department: DepartmentType.drawing,
    status: MachineStatus.underRepair,
  );

  final strandingMachine = MachineModel(
    id: 'ST01',
    code: 'ST01',
    name: 'Stranding Line 01',
    subCategory: 'Stranding',
    department: DepartmentType.stranding,
    status: MachineStatus.underRepair,
  );

  final completedWorkOrder = WorkOrderModel(
    id: 'wo-101',
    title: 'Hydraulic leak repair',
    description: 'Line stopped due to low pressure',
    machineId: 'DR01',
    type: WorkOrderType.breakdown,
    status: WorkOrderStatus.completed,
    priority: Priority.high,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    completedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    rootCause: 'Failed O-ring gasket',
    actionsTaken: 'Replaced O-ring and replenished hydraulic oil',
  );

  group('WorkOrderStateMachine: Bounce-Back Transition Validation', () {
    test('completed -> verified is valid (outcome: fixed)', () {
      expect(
        WorkOrderStateMachine.canTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.verified,
        ),
        isTrue,
      );
      expect(
        () => WorkOrderStateMachine.validateTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.verified,
        ),
        returnsNormally,
      );
    });

    test('completed -> inProgress is valid (outcome: needs_followup or not_fixed)', () {
      expect(
        WorkOrderStateMachine.canTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.inProgress,
        ),
        isTrue,
      );
      expect(
        () => WorkOrderStateMachine.validateTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.inProgress,
        ),
        returnsNormally,
      );
      expect(
        WorkOrderStateMachine.getAllowedNextStates(WorkOrderStatus.completed),
        containsAll([WorkOrderStatus.verified, WorkOrderStatus.inProgress]),
      );
    });

    test('completed -> open is strictly prohibited', () {
      expect(
        WorkOrderStateMachine.canTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.open,
        ),
        isFalse,
      );
      expect(
        () => WorkOrderStateMachine.validateTransition(
          WorkOrderStatus.completed,
          WorkOrderStatus.open,
        ),
        throwsA(isA<IllegalStateTransitionException>()),
      );
    });
  });

  group('WorkOrderSecurityGuard: Check Phase RBAC & Scope', () {
    test('Operator can confirm test run for their own department machine', () {
      final op = MockUsers.drawingLead;
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(op, drawingMachine),
        returnsNormally,
      );
    });

    test('Operator is strictly rejected from confirming test run for different department', () {
      final op = MockUsers.drawingLead;
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(op, strandingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Production Supervisor from Department A is accepted for Department A and rejected for Department B', () {
      final prodSupDeptA = MockUsers.productionSupervisor.copyWith(
        department: DepartmentType.drawing,
      );
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(prodSupDeptA, drawingMachine),
        returnsNormally,
      );
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(prodSupDeptA, strandingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Technician and Plant Manager cannot confirm test runs', () {
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(MockUsers.electricalTech, drawingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(MockUsers.plantManager, drawingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });
  });

  group('WorkOrderHandshakeMutator: Check Phase & Bounce-Back', () {
    test('outcome: fixed transitions ticket to verified and records check', () {
      final op = MockUsers.drawingLead;
      final verifiedWo = WorkOrderHandshakeMutator.applyConfirmTestRun(
        completedWorkOrder,
        op,
        outcome: 'fixed',
        confirmedDowntimeMinutes: 45,
        machine: drawingMachine,
      );

      expect(verifiedWo.status, equals(WorkOrderStatus.verified));
      expect(verifiedWo.checks.length, equals(1));
      expect(verifiedWo.checks.first['outcome'], equals('fixed'));
      expect(verifiedWo.checks.first['confirmed_downtime_minutes'], equals(45));
      expect(verifiedWo.checks.first['by'], equals(op.id));
      expect(verifiedWo.activityLogs.last.stepName, equals('TEST_RUN_PASSED'));
      expect(verifiedWo.latestRejectionNotes, isNull);
    });

    test('outcome: needs_followup bounces back to inProgress and requires comments', () {
      final op = MockUsers.drawingLead;

      // Without comments must throw ArgumentError
      expect(
        () => WorkOrderHandshakeMutator.applyConfirmTestRun(
          completedWorkOrder,
          op,
          outcome: 'needs_followup',
          comments: '',
          machine: drawingMachine,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // With comments succeeds and bounces back to inProgress
      final bouncedWo = WorkOrderHandshakeMutator.applyConfirmTestRun(
        completedWorkOrder,
        op,
        outcome: 'needs_followup',
        comments: 'Vibration detected at 800 RPM in drive gear',
        machine: drawingMachine,
      );

      expect(bouncedWo.status, equals(WorkOrderStatus.inProgress));
      expect(bouncedWo.checks.length, equals(1));
      expect(bouncedWo.checks.first['outcome'], equals('needs_followup'));
      expect(bouncedWo.checks.first['notes'], equals('Vibration detected at 800 RPM in drive gear'));
      expect(bouncedWo.latestRejectionNotes, equals('Vibration detected at 800 RPM in drive gear'));
    });

    test('outcome: not_fixed bounces back to inProgress with rejection notes', () {
      final prodSup = MockUsers.productionSupervisor;

      final bouncedWo = WorkOrderHandshakeMutator.applyConfirmTestRun(
        completedWorkOrder,
        prodSup,
        outcome: 'not_fixed',
        comments: 'Wire snapping persists immediately upon line acceleration',
        machine: drawingMachine,
      );

      expect(bouncedWo.status, equals(WorkOrderStatus.inProgress));
      expect(bouncedWo.latestRejectionNotes, equals('Wire snapping persists immediately upon line acceleration'));
      expect(bouncedWo.activityLogs.last.stepName, equals('TEST_RUN_REJECTED'));
    });
  });

  group('Outbox & Remote Deserialization of Checks', () {
    test('WorkOrderOutboxFactory encodes outcome and comments', () {
      final cmd = WorkOrderOutboxFactory.confirmTestRun(
        completedWorkOrder,
        outcome: 'needs_followup',
        comments: 'Check lubrication system',
        confirmedDowntimeMinutes: 60,
      );

      expect(cmd.commandType, equals('confirm_test_run'));
      expect(cmd.payload['outcome'], equals('needs_followup'));
      expect(cmd.payload['comments'], equals('Check lubrication system'));
      expect(cmd.payload['confirmed_downtime_minutes'], equals(60));
    });

    test('confirm RPC parameters match the outcome-aware SQL contract', () {
      final cmd = WorkOrderOutboxFactory.confirmTestRun(
        completedWorkOrder,
        outcome: 'needs_followup',
        comments: 'Check lubrication system',
        confirmedDowntimeMinutes: 60,
        expectedVersion: 7,
      );
      final params = confirmTestRunRpcParams(cmd);

      expect(params.keys, containsAll([
        'p_command_id',
        'p_wo_id',
        'p_expected_version',
        'p_outcome',
        'p_comments',
        'p_confirmed_downtime_minutes',
        'p_occurred_at',
      ]));
      expect(params['p_command_id'], equals(cmd.commandId));
      expect(params['p_wo_id'], equals(completedWorkOrder.id));
      expect(params['p_expected_version'], equals(7));
      expect(params['p_outcome'], equals('needs_followup'));
      expect(params['p_comments'], equals('Check lubrication system'));
      expect(params['p_confirmed_downtime_minutes'], equals(60));
      expect(
        params['p_occurred_at'],
        equals(cmd.occurredAt.toUtc().toIso8601String()),
      );
    });

    test('WorkOrderRemoteMapper restores checks array from Supabase row', () {
      final row = {
        'id': 'wo-check-99',
        'title': 'Test ticket',
        'description': 'Check phase test',
        'machine_id': 'RW01',
        'status': 'inProgress',
        'type': 'breakdown',
        'priority': 'high',
        'created_at': DateTime.now().toIso8601String(),
        'version': 2,
        'checks': [
          {
            'at': DateTime.now().toIso8601String(),
            'by': 'op-user-1',
            'outcome': 'needs_followup',
            'notes': 'Tensioner misalignment',
            'confirmed_downtime_minutes': 30,
          }
        ],
      };

      final wo = WorkOrderRemoteMapper.fromSupabaseRow(row);
      expect(wo.status, equals(WorkOrderStatus.inProgress));
      expect(wo.checks.length, equals(1));
      expect(wo.checks.first['outcome'], equals('needs_followup'));
      expect(wo.latestRejectionNotes, equals('Tensioner misalignment'));
    });
  });
}
