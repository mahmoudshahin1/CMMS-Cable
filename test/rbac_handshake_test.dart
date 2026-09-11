import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_state.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/app_permission.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';

void main() {
  group('RBAC AuthCubit & Permission Matrix Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
    });

    tearDown(() {
      authCubit.close();
    });

    test('Initial user defaults to Maintenance Supervisor', () {
      expect(authCubit.state, isA<Authenticated>());
      final user = (authCubit.state as Authenticated).user;
      expect(user.role, equals(UserRole.maintenanceSupervisor));
    });

    test('Switching persona updates active user and role', () {
      authCubit.switchUser(MockUsers.operatorUser);
      expect(authCubit.currentUser?.role, equals(UserRole.operator));
      expect(authCubit.currentUser?.email, equals(MockUsers.operatorUser.email));

      authCubit.switchUser(MockUsers.electricalTech);
      expect(authCubit.currentUser?.role, equals(UserRole.maintenanceTech));
      expect(authCubit.currentUser?.speciality, equals('Electrical'));
    });

    test('Operator permissions: Can report downtime & confirm test run, cannot assign techs or complete repair', () {
      authCubit.switchUser(MockUsers.operatorUser);

      expect(authCubit.can(AppPermission.logDowntime), isTrue);
      expect(authCubit.can(AppPermission.confirmTestRun), isTrue);
      expect(authCubit.can(AppPermission.recordProcessLogs), isTrue);

      expect(authCubit.can(AppPermission.assignTechnician), isFalse);
      expect(authCubit.can(AppPermission.startRepair), isFalse);
      expect(authCubit.can(AppPermission.completeRepair), isFalse);
      expect(authCubit.can(AppPermission.approveAndClose), isFalse);
    });

    test('Maintenance Technician permissions: Can start repair, add parts, complete repair; cannot assign or close', () {
      authCubit.switchUser(MockUsers.mechanicalTech);

      expect(authCubit.can(AppPermission.startRepair), isTrue);
      expect(authCubit.can(AppPermission.addSpareParts), isTrue);
      expect(authCubit.can(AppPermission.completeRepair), isTrue);

      expect(authCubit.can(AppPermission.assignTechnician), isFalse);
      expect(authCubit.can(AppPermission.confirmTestRun), isFalse);
      expect(authCubit.can(AppPermission.approveAndClose), isFalse);
    });

    test('Maintenance Supervisor permissions: Can assign tech and approve/close ticket', () {
      authCubit.switchUser(MockUsers.maintenanceSupervisor);

      expect(authCubit.can(AppPermission.assignTechnician), isTrue);
      expect(authCubit.can(AppPermission.approveAndClose), isTrue);

      expect(authCubit.can(AppPermission.startRepair), isFalse);
      expect(authCubit.can(AppPermission.confirmTestRun), isFalse);
    });

    test('Plant Manager has read-only analytics access and all operational gates hidden', () {
      authCubit.switchUser(MockUsers.plantManager);

      expect(authCubit.can(AppPermission.viewAnalytics), isTrue);
      expect(authCubit.can(AppPermission.exportReports), isTrue);

      expect(authCubit.can(AppPermission.logDowntime), isFalse);
      expect(authCubit.can(AppPermission.assignTechnician), isFalse);
      expect(authCubit.can(AppPermission.startRepair), isFalse);
      expect(authCubit.can(AppPermission.confirmTestRun), isFalse);
    });
  });

  group('5-Step Handshake Lifecycle Enum Consistency', () {
    test('MachineStatus underRepair is downtime', () {
      expect(MachineStatus.underRepair.isDowntime, isTrue);
      expect(MachineStatus.underRepair.displayName, equals('Under Repair'));
    });

    test('WorkOrderStatus verified status and aliases match requirements', () {
      expect(WorkOrderStatus.pending, equals(WorkOrderStatus.open));
      expect(WorkOrderStatus.closed, equals(WorkOrderStatus.verifiedClosed));
      expect(WorkOrderStatus.verified.shortName, equals('VERIFIED'));
      expect(WorkOrderStatus.verified.isActive, isTrue);
      expect(WorkOrderStatus.verifiedClosed.isActive, isFalse);
    });
  });
}
