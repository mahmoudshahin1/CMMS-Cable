import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/repair_step_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_handshake_mutator.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/structured_repair_steps_section.dart';

void main() {
  group('Structured Repair Steps Unit & Logic Tests', () {
    test('RepairStepModel serializes to and from JSON accurately', () {
      final now = DateTime.utc(2026, 11, 4, 18, 30);
      final step = RepairStepModel(
        id: 'step-01',
        description: 'Replaced capstan bearing',
        partName: 'Ball Bearing 6205',
        partNumber: 'PN-BB6205',
        quantity: 2,
        completedAt: now,
      );

      final json = step.toJson();
      expect(json['id'], 'step-01');
      expect(json['description'], 'Replaced capstan bearing');
      expect(json['part_name'], 'Ball Bearing 6205');
      expect(json['part_number'], 'PN-BB6205');
      expect(json['quantity'], 2);
      expect(json['completed_at'], now.toIso8601String());

      final restored = RepairStepModel.fromJson(json);
      expect(restored, equals(step));
    });

    test('WorkOrderHandshakeMutator.applyComplete auto-derives actionsTaken when empty', () {
      const caller = UserModel(
        id: 'tech-1',
        email: 'tech@energyacables.com',
        name: 'Ahmed Tech',
        role: UserRole.maintenanceTech,
        department: DepartmentType.drawing,
      );

      final wo = WorkOrderModel(
        id: 'wo-1',
        title: 'Capstan breakdown',
        description: 'Vibration noise',
        machineId: 'DW01',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.inProgress,
        priority: Priority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        assignedToTechnicianId: 'tech-1',
      );

      final steps = [
        const RepairStepModel(
          id: 's1',
          description: 'Dismantled bearing housing',
        ),
        const RepairStepModel(
          id: 's2',
          description: 'Replaced drive pulley',
          partName: 'Pulley 200mm',
          quantity: 1,
        ),
      ];

      final updated = WorkOrderHandshakeMutator.applyComplete(
        wo,
        caller: caller,
        rootCause: 'Bearing race fatigue',
        actionsTaken: '',
        repairSteps: steps,
      );

      expect(updated.status, WorkOrderStatus.completed);
      expect(updated.repairSteps.length, 2);
      expect(updated.actionsTaken, contains('Dismantled bearing housing'));
      expect(updated.actionsTaken, contains('Replaced drive pulley'));
    });
  });

  group('StructuredRepairStepsSection Widget Tests', () {
    testWidgets('renders existing repair steps and allows adding a new step', (tester) async {
      final initialWo = WorkOrderModel(
        id: 'wo-2',
        title: 'Extruder barrel trip',
        description: 'Heater zone 2 alarm',
        machineId: 'EX01',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.inProgress,
        priority: Priority.high,
        createdAt: DateTime.now(),
        repairSteps: const [
          RepairStepModel(
            id: 'step-existing',
            description: 'Inspected thermocouple resistance',
          ),
        ],
      );

      List<RepairStepModel> latestSteps = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StructuredRepairStepsSection(
                workOrder: initialWo,
                isEditable: true,
                onStepsChanged: (steps) => latestSteps = steps,
              ),
            ),
          ),
        ),
      );

      expect(find.text('STRUCTURED REPAIR STEPS'), findsOneWidget);
      expect(find.text('Inspected thermocouple resistance'), findsOneWidget);

      // Enter a new step
      final descField = find.byType(TextField).first;
      await tester.enterText(descField, 'Replaced SSR relay module');
      await tester.pump();

      final addButton = find.text('Add');
      await tester.tap(addButton);
      await tester.pump();

      expect(find.text('Replaced SSR relay module'), findsOneWidget);
      expect(latestSteps.length, 2);
      expect(latestSteps.last.description, 'Replaced SSR relay module');
    });
  });
}
