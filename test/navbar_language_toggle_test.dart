import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orning_and_evening_remembrances/core/localization/locale_cubit.dart';
import 'package:orning_and_evening_remembrances/core/navigation/role_nav_config.dart';
import 'package:orning_and_evening_remembrances/core/navigation/main_navigation_shell.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'helpers/fake_auth_repository.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/spare_part_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/presentation/cubit/machine_cubit.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/repositories/machine_repository.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/process_log_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';

class _FakeWorkOrderRepository implements WorkOrderRepository {
  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async => [];
  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async => null;
  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(WorkOrderStatus status) async => [];
  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(String id) async => [];
  @override
  Future<WorkOrderModel> createWorkOrder(WorkOrderModel wo, {dynamic caller}) async => wo;
  @override
  Future<void> updateWorkOrderStatus(String id, WorkOrderStatus s, {dynamic caller}) async {}
  @override
  Future<void> assignTechnician(String id, String tId, String sId, {dynamic caller, String? technicianName}) async {}
  @override
  Future<void> startRepair(String id, {required dynamic caller}) async {}
  @override
  Future<void> addSparePart(String id, SparePartModel sp, {dynamic caller}) async {}
  @override
  Future<void> completeWorkOrder(String id, {required String rootCause, required String actionsTaken, dynamic caller}) async {}
  @override
  Future<void> confirmTestRun(String id, {required dynamic caller}) async {}
  @override
  Future<void> approveAndClose(String id, {required dynamic caller}) async {}
}

class _FakeMachineRepository implements MachineRepository {
  @override
  Future<List<MachineModel>> getAllMachines() async => [];
  @override
  Future<List<MachineModel>> refreshFromRemote() async => [];
  @override
  Future<MachineModel?> getMachineById(String id) async => null;
  @override
  Future<List<MachineModel>> getMachinesByDepartment(DepartmentType department) async => [];
  @override
  Future<List<MachineModel>> getMachinesByStatus(MachineStatus status) async => [];
  @override
  Future<void> updateMachineStatus(String machineId, MachineStatus newStatus) async {}
  @override
  Future<void> saveProcessLog(ProcessLogModel log) async {}
  @override
  Future<List<ProcessLogModel>> getProcessLogsForMachine(String machineId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Bar Dynamic Language Switching Tests', () {
    testWidgets('RoleNavConfig labels dynamically reflect Arabic vs English', (tester) async {
      final localeCubit = LocaleCubit();
      final authCubit = AuthCubit(FakeAuthRepository())..switchUser(MockUsers.plantManager);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final config = RoleNavConfig.build(
                  context,
                  UserRole.plantManager,
                  0,
                );
                return Scaffold(
                  bottomNavigationBar: BottomNavigationBar(
                    items: config.navItems,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Default is Arabic ('ar')
      expect(find.text('لوحة المؤشرات'), findsOneWidget);
      expect(find.text('أرضية المصنع'), findsOneWidget);
      expect(find.text('أوامر الصيانة'), findsOneWidget);

      // Switch language to English
      localeCubit.setLocale(const Locale('en'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Executive KPI'), findsOneWidget);
      expect(find.text('Factory Floor'), findsOneWidget);
      expect(find.text('Work Orders'), findsOneWidget);

      // Switch back to Arabic
      localeCubit.setLocale(const Locale('ar'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('لوحة المؤشرات'), findsOneWidget);
      expect(find.text('أرضية المصنع'), findsOneWidget);
      expect(find.text('أوامر الصيانة'), findsOneWidget);
    });

    testWidgets('MainNavigationShell bottom bar rebuilds on LocaleCubit emit', (tester) async {
      final localeCubit = LocaleCubit();
      final authCubit = AuthCubit(FakeAuthRepository())..switchUser(MockUsers.electricalTech);
      final workOrderCubit = WorkOrderCubit(_FakeWorkOrderRepository());
      final machineCubit = MachineCubit(_FakeMachineRepository());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<WorkOrderCubit>.value(value: workOrderCubit),
            BlocProvider<MachineCubit>.value(value: machineCubit),
          ],
          child: const MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );

      // Initial Arabic state for technician (selected tab is index 0)
      expect(find.text('مهامي المسندة'), findsOneWidget);

      // Toggle to English
      localeCubit.toggleLanguage();
      await tester.pump(const Duration(milliseconds: 400));

      // Verified English active tab appears
      expect(find.text('My Tasks'), findsOneWidget);

      // Switch to notifications tab
      await tester.tap(find.byIcon(Icons.notifications_active_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Alerts'), findsOneWidget);

      // Toggle back to Arabic while on notifications tab
      localeCubit.toggleLanguage();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('التنبيهات'), findsOneWidget);
    });
  });
}
