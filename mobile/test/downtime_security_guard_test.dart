import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/errors/security_exceptions.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/downtime/domain/logic/downtime_security_guard.dart';

void main() {
  final drawingMachine = MachineModel(
    id: 'mc-draw-01',
    code: 'DR-01',
    name: 'Drawing Line 1',
    department: DepartmentType.drawing,
    subCategory: 'RBD',
    status: MachineStatus.running,
  );

  final strandingMachine = MachineModel(
    id: 'mc-strand-01',
    code: 'ST-01',
    name: 'Stranding Line 1',
    department: DepartmentType.stranding,
    subCategory: 'Buncher',
    status: MachineStatus.running,
  );

  group('DowntimeSecurityGuard: Create Downtime Authorization & Department Isolation', () {
    test('Line Operator can create downtime for machine in their assigned department', () {
      final drawingOp = MockUsers.drawingLead;
      expect(
        () => DowntimeSecurityGuard.validateCreate(drawingOp, drawingMachine),
        returnsNormally,
      );
    });

    test('Line Operator is strictly blocked from creating downtime for different department', () {
      final drawingOp = MockUsers.drawingLead;
      expect(
        () => DowntimeSecurityGuard.validateCreate(drawingOp, strandingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Production Supervisor is allowed for their own department', () {
      final prodSupervisorDrawing = MockUsers.productionSupervisor.copyWith(
        department: DepartmentType.drawing,
      );
      expect(
        () => DowntimeSecurityGuard.validateCreate(prodSupervisorDrawing, drawingMachine),
        returnsNormally,
      );
    });

    test('Production Supervisor is strictly blocked from cross-department downtime reporting', () {
      final prodSupervisorDrawing = MockUsers.productionSupervisor.copyWith(
        department: DepartmentType.drawing,
      );
      expect(
        () => DowntimeSecurityGuard.validateCreate(prodSupervisorDrawing, strandingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Plant Manager is authorized across all departments', () {
      final plantManager = MockUsers.plantManager;
      expect(
        () => DowntimeSecurityGuard.validateCreate(plantManager, drawingMachine),
        returnsNormally,
      );
      expect(
        () => DowntimeSecurityGuard.validateCreate(plantManager, strandingMachine),
        returnsNormally,
      );
    });

    test('Maintenance Supervisor is authorized across all departments', () {
      final maintSup = MockUsers.maintenanceSupervisor;
      expect(
        () => DowntimeSecurityGuard.validateCreate(maintSup, drawingMachine),
        returnsNormally,
      );
      expect(
        () => DowntimeSecurityGuard.validateCreate(maintSup, strandingMachine),
        returnsNormally,
      );
    });

    test('Maintenance Technician is blocked from reporting downtime', () {
      final tech = MockUsers.electricalTech;
      expect(
        () => DowntimeSecurityGuard.validateCreate(tech, drawingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });
  });

  group('DowntimeSecurityGuard: Close Downtime Authorization (Option A: Supervisors Only)', () {
    test('Line Operator is blocked from closing downtime logs', () {
      final drawingOp = MockUsers.drawingLead;
      expect(
        () => DowntimeSecurityGuard.validateClose(drawingOp, drawingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Maintenance Technician is blocked from closing downtime logs', () {
      final tech = MockUsers.mechanicalTech;
      expect(
        () => DowntimeSecurityGuard.validateClose(tech, drawingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Production Supervisor is allowed to close downtime in their own department', () {
      final prodSupervisorDrawing = MockUsers.productionSupervisor.copyWith(
        department: DepartmentType.drawing,
      );
      expect(
        () => DowntimeSecurityGuard.validateClose(prodSupervisorDrawing, drawingMachine),
        returnsNormally,
      );
    });

    test('Production Supervisor is blocked from closing downtime in another department', () {
      final prodSupervisorDrawing = MockUsers.productionSupervisor.copyWith(
        department: DepartmentType.drawing,
      );
      expect(
        () => DowntimeSecurityGuard.validateClose(prodSupervisorDrawing, strandingMachine),
        throwsA(isA<UnauthorizedRoleException>()),
      );
    });

    test('Plant Manager and Maintenance Supervisor can close downtime across all departments', () {
      final plantManager = MockUsers.plantManager;
      final maintSup = MockUsers.maintenanceSupervisor;

      expect(
        () => DowntimeSecurityGuard.validateClose(plantManager, drawingMachine),
        returnsNormally,
      );
      expect(
        () => DowntimeSecurityGuard.validateClose(plantManager, strandingMachine),
        returnsNormally,
      );
      expect(
        () => DowntimeSecurityGuard.validateClose(maintSup, drawingMachine),
        returnsNormally,
      );
      expect(
        () => DowntimeSecurityGuard.validateClose(maintSup, strandingMachine),
        returnsNormally,
      );
    });
  });
}
