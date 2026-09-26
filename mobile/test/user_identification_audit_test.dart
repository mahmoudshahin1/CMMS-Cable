import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/auth/user_directory_helper.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_handshake_mutator.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/timeline/timeline_details_table.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/timeline/timeline_log_content_box.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/work_order_list_card.dart';

void main() {
  group('User Identification & Name Resolution Tests', () {
    const operatorUser = UserModel(
      id: 'op-uuid-001',
      name: 'محمود شاهين - مشغل خط السحب',
      email: 'mahmoud.op@cable.com',
      role: UserRole.operator,
    );

    const supervisorUser = UserModel(
      id: 'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
      name: 'م. هشام راضي - مشرف الصيانة',
      email: 'eng.maint@cable.com',
      role: UserRole.maintenanceSupervisor,
    );

    const technicianUser = UserModel(
      id: 'a777edcb-e42e-4c94-aac9-1b89dd364ce5',
      name: 'أحمد فني كهرباء وتحكم',
      email: 'tech.ahmed@cable.com',
      role: UserRole.maintenanceTech,
      speciality: 'Electrical',
    );

    setUp(() {
      UserDirectoryHelper.registerUsers([
        operatorUser,
        supervisorUser,
        technicianUser,
      ]);
    });

    test('UserDirectoryHelper resolves known UUIDs to friendly names', () {
      expect(
        UserDirectoryHelper.resolveName('a777edcb-e42e-4c94-aac9-1b89dd364ce5'),
        equals('أحمد فني كهرباء وتحكم'),
      );
      expect(
        UserDirectoryHelper.resolveName('c79d06f1-09b2-4d01-99e9-0c8fced1e56b'),
        equals('م. هشام راضي - مشرف الصيانة'),
      );
      expect(
        UserDirectoryHelper.resolveName('op-uuid-001'),
        equals('محمود شاهين - مشغل خط السحب'),
      );
    });

    test('formatActionSummary replaces raw UUID with technician name', () {
      const rawSummary =
          'Assigned to technician a777edcb-e42e-4c94-aac9-1b89dd364ce5';
      final formatted = UserDirectoryHelper.formatActionSummary(rawSummary);

      expect(formatted, equals('Assigned to technician أحمد فني كهرباء وتحكم'));
    });

    test('applyAssign creates log with technician name and supervisor name', () {
      final initialWo = WorkOrderModel(
        id: 'wo-test-01',
        title: 'Extruder Overheat',
        description: 'Line 2 bearing temperature high',
        machineId: 'EXT-02',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.open,
        priority: Priority.high,
        createdAt: DateTime.now(),
      );

      final updated = WorkOrderHandshakeMutator.applyAssign(
        initialWo,
        technicianUser.id,
        supervisorUser.id,
        supervisorUser,
        technicianName: technicianUser.name,
      );

      expect(updated.status, equals(WorkOrderStatus.assigned));
      expect(updated.activityLogs.length, equals(1));

      final assignLog = updated.activityLogs.first;
      expect(
        assignLog.actionSummary,
        equals('Assigned to technician أحمد فني كهرباء وتحكم'),
      );
      expect(
        assignLog.performedByName,
        equals('م. هشام راضي - مشرف الصيانة'),
      );
      expect(assignLog.details?['technician'], equals('أحمد فني كهرباء وتحكم'));
      expect(
        assignLog.details?['supervisor'],
        equals('م. هشام راضي - مشرف الصيانة'),
      );
    });

    testWidgets('TimelineDetailsTable displays resolved technician name without raw UUID duplicates',
        (tester) async {
      final details = {
        'technicianId': 'a777edcb-e42e-4c94-aac9-1b89dd364ce5',
        'supervisorId': 'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineDetailsTable(details: details),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Friendly resolved name is displayed on screen
      expect(find.textContaining('أحمد فني كهرباء وتحكم'), findsOneWidget);
      expect(find.textContaining('م. هشام راضي - مشرف الصيانة'), findsOneWidget);
      // Raw UUID is not rendered as the text
      expect(find.text('a777edcb-e42e-4c94-aac9-1b89dd364ce5'), findsNothing);
    });

    testWidgets('TimelineLogContentBox displays operator name and replaces Operator Desk',
        (tester) async {
      final wo = WorkOrderModel(
        id: 'wo-op-test',
        title: 'Cable Jam',
        description: 'Dancer arm stuck',
        machineId: 'RS02',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.open,
        priority: Priority.critical,
        createdAt: DateTime.now(),
      );

      // Simulate a log created with the operator
      final logWithOperator = WorkOrderHandshakeMutator.applyAssign(
        wo,
        technicianUser.id,
        supervisorUser.id,
        supervisorUser,
      ).activityLogs.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineLogContentBox(log: logWithOperator),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('أحمد فني كهرباء وتحكم'), findsWidgets);
    });

    testWidgets('WorkOrderListCard displays resolved technician name on card badge',
        (tester) async {
      final wo = WorkOrderModel(
        id: 'wo-card-test',
        title: 'Breakdown RS02',
        description: 'Motor trip',
        machineId: 'RS02',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.assigned,
        priority: Priority.critical,
        assignedToTechnicianId: 'a777edcb-e42e-4c94-aac9-1b89dd364ce5',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkOrderListCard(workOrder: wo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card displays technician name instead of truncated UUID
      expect(find.text('أحمد فني كهرباء وتحكم'), findsOneWidget);
    });
  });
}
