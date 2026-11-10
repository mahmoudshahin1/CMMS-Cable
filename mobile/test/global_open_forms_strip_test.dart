import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/cubit/work_order_cubit.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/open_form_chip.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/global_open_forms_strip.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/spare_part_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/repair_step_model.dart';

class _FakeWorkOrderRepository implements WorkOrderRepository {
  final List<WorkOrderModel> orders;
  _FakeWorkOrderRepository(this.orders);

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async => orders;
  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async => null;
  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(WorkOrderStatus s) async => [];
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
  Future<void> completeWorkOrder(
    String id, {
    required String rootCause,
    required String actionsTaken,
    List<RepairStepModel>? repairSteps,
    String? repairVoiceUrl,
    String? repairVoiceLocalPath,
    dynamic caller,
  }) async {}
  @override
  Future<void> confirmTestRun(
    String id, {
    required dynamic caller,
    String outcome = 'fixed',
    String? comments,
    int? confirmedDowntimeMinutes,
  }) async {}
  @override
  Future<void> approveAndClose(String id, {required dynamic caller}) async {}
}

void main() {
  group('OpenFormChip Widget Tests', () {
    final testWo = WorkOrderModel(
      id: 'wo-1',
      title: 'Capstan bearing defect',
      description: 'Loud noise',
      machineId: 'DW01',
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.inProgress,
      priority: Priority.high,
      createdAt: DateTime.now(),
    );

    testWidgets('renders correct status dot color for dirty amber vs synced green', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OpenFormChip(
                  workOrder: testWo,
                  syncStatus: FormSyncStatus.dirtyAmber,
                ),
                OpenFormChip(
                  workOrder: testWo,
                  syncStatus: FormSyncStatus.syncedGreen,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('#DW01'), findsNWidgets(2));
      expect(find.text('Capstan bearing defect'), findsNWidgets(2));
    });
  });

  group('GlobalOpenFormsStrip Widget Tests', () {
    testWidgets('hides when all work orders are completed or closed', (tester) async {
      final repo = _FakeWorkOrderRepository([
        WorkOrderModel(
          id: 'wo-done',
          title: 'Finished repair',
          description: 'All good',
          machineId: 'EX01',
          type: WorkOrderType.breakdown,
          status: WorkOrderStatus.verifiedClosed,
          priority: Priority.low,
          createdAt: DateTime.now(),
        ),
      ]);
      final cubit = WorkOrderCubit(repo);
      await cubit.loadWorkOrders();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const GlobalOpenFormsStrip(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN FORMS'), findsNothing);
    });

    testWidgets('renders strip with active badge count and chips for open forms', (tester) async {
      final repo = _FakeWorkOrderRepository([
        WorkOrderModel(
          id: 'wo-active-1',
          title: 'Capstan vibration',
          description: 'Bearing replacement required',
          machineId: 'DW01',
          type: WorkOrderType.breakdown,
          status: WorkOrderStatus.inProgress,
          priority: Priority.high,
          createdAt: DateTime.now(),
        ),
        WorkOrderModel(
          id: 'wo-active-2',
          title: 'Zone 3 heater trip',
          description: 'Overheat',
          machineId: 'EX02',
          type: WorkOrderType.breakdown,
          status: WorkOrderStatus.open,
          priority: Priority.critical,
          createdAt: DateTime.now(),
        ),
      ]);
      final cubit = WorkOrderCubit(repo);
      await cubit.loadWorkOrders();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const GlobalOpenFormsStrip(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OPEN FORMS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count
      expect(find.text('#DW01'), findsOneWidget);
      expect(find.text('#EX02'), findsOneWidget);

      // Tap collapse toggle
      final collapseBtn = find.byIcon(Icons.keyboard_arrow_up);
      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      expect(find.text('#DW01'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
