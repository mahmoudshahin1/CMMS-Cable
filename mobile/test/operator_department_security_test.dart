import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/errors/security_exceptions.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/logic/work_order_security_guard.dart';

void main() {
  group('Line Operator Department Resolution & Immunity to Null', () {
    test('Mock operator users have strictly resolved departments', () {
      expect(MockUsers.drawingLead.department, DepartmentType.drawing);
      expect(MockUsers.strandingLead.department, DepartmentType.stranding);
      expect(MockUsers.ccvLead.department, DepartmentType.ccv);
      expect(MockUsers.extrusionLead.department, DepartmentType.extrusion);
      expect(MockUsers.assemblyLead.department, DepartmentType.assembly);
      expect(MockUsers.screeningLead.department, DepartmentType.screening);
      expect(MockUsers.tapeArmourLead.department, DepartmentType.tapeArmour);
    });

    test('UserModel.department getter never returns null for operators even if created with null', () {
      final nullDeptOperator = UserModel(
        id: 'op-draw-1',
        name: 'مصطفى كمال',
        email: 'op.drawing@cable.com',
        role: UserRole.operator,
        department: null,
      );

      expect(nullDeptOperator.department, DepartmentType.drawing);
    });

    test('DepartmentTypeExtension.fromString resolves Arabic and English names accurately', () {
      expect(DepartmentTypeExtension.fromString('قسم سحب الأسلاك'), DepartmentType.drawing);
      expect(DepartmentTypeExtension.fromString('سحب'), DepartmentType.drawing);
      expect(DepartmentTypeExtension.fromString('drawing'), DepartmentType.drawing);

      expect(DepartmentTypeExtension.fromString('قسم الجدل والتجميع'), DepartmentType.stranding);
      expect(DepartmentTypeExtension.fromString('جدل'), DepartmentType.stranding);
      expect(DepartmentTypeExtension.fromString('stranding'), DepartmentType.stranding);

      expect(DepartmentTypeExtension.fromString('خطوط الفلكنة المستمرة (CCV)'), DepartmentType.ccv);
      expect(DepartmentTypeExtension.fromString('ccv'), DepartmentType.ccv);

      expect(DepartmentTypeExtension.fromString('عزل/بثق'), DepartmentType.extrusion);
      expect(DepartmentTypeExtension.fromString('extrusion'), DepartmentType.extrusion);
      expect(DepartmentTypeExtension.fromString('تجميع/تسليح'), DepartmentType.assembly);
      expect(DepartmentTypeExtension.fromString('assembly'), DepartmentType.assembly);
      expect(DepartmentTypeExtension.fromString('حجب/شريط'), DepartmentType.screening);
      expect(DepartmentTypeExtension.fromString('screening'), DepartmentType.screening);
      expect(DepartmentTypeExtension.fromString('تدريع'), DepartmentType.tapeArmour);
      expect(DepartmentTypeExtension.fromString('tapeArmour'), DepartmentType.tapeArmour);
    });

    test('DepartmentTypeExtension.resolveOperatorDepartment falls back cleanly from email', () {
      final dept = DepartmentTypeExtension.resolveOperatorDepartment(
        email: 'op.assembly@cable.com',
      );
      expect(dept, DepartmentType.assembly);
    });
  });

  group('WorkOrderSecurityGuard Department Boundary Enforcement', () {
    final drawingMachine = MachineModel(
      id: 'DM01',
      code: 'DM01',
      name: 'Rod Breakdown Mill 01',
      department: DepartmentType.drawing,
      subCategory: 'RBD',
      status: MachineStatus.running,
    );

    final strandingMachine = MachineModel(
      id: 'BN01',
      code: 'BN01',
      name: 'Buncher 630 - Line 01',
      department: DepartmentType.stranding,
      subCategory: 'Buncher',
      status: MachineStatus.running,
    );

    test('Operator can report breakdown for machine in their assigned department', () {
      final drawingOp = MockUsers.drawingLead;

      expect(
        () => WorkOrderSecurityGuard.validateCreate(
          drawingOp,
          drawingMachine,
        ),
        returnsNormally,
      );
    });

    test('Operator CANNOT report breakdown for machine in another department', () {
      final drawingOp = MockUsers.drawingLead;

      expect(
        () => WorkOrderSecurityGuard.validateCreate(
          drawingOp,
          strandingMachine,
        ),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Supervisors can create requests for any department machine', () {
      final maintSupervisor = MockUsers.maintenanceSupervisor;
      final prodSupervisor = MockUsers.productionSupervisor;

      expect(
        () => WorkOrderSecurityGuard.validateCreate(
          maintSupervisor,
          strandingMachine,
        ),
        returnsNormally,
      );

      expect(
        () => WorkOrderSecurityGuard.validateCreate(
          prodSupervisor,
          strandingMachine,
        ),
        returnsNormally,
      );
    });

    test('Operator can confirm test run only for their department machine', () {
      final drawingOp = MockUsers.drawingLead;

      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(
          drawingOp,
          drawingMachine,
        ),
        returnsNormally,
      );

      expect(
        () => WorkOrderSecurityGuard.validateConfirmTestRun(
          drawingOp,
          strandingMachine,
        ),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });
  });

  group('Plant Floor Operator UI Scoping Logic', () {
    test('Operator hasDeptScope evaluates to true even without explicit department property', () {
      final op = UserModel(
        id: 'op-anon-1',
        name: 'مشغل خط',
        email: 'op.ccv@cable.com',
        role: UserRole.operator,
      );

      final isOperator = op.role == UserRole.operator;
      final userDept = op.department;
      final isPlantManager = op.role == UserRole.plantManager;

      final hasDeptScope = isOperator || (userDept != null && !isPlantManager);

      expect(hasDeptScope, isTrue);
      expect(userDept, DepartmentType.ccv);
    });

    test('Plant Manager hasDeptScope evaluates to false to allow overview of all departments', () {
      final pm = MockUsers.plantManager;
      final isOperator = pm.role == UserRole.operator;
      final userDept = pm.department;
      final isPlantManager = pm.role == UserRole.plantManager;

      final hasDeptScope = isOperator || (userDept != null && !isPlantManager);

      expect(hasDeptScope, isFalse);
    });
  });
}
