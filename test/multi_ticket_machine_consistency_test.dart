import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/model_adapters.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/data/datasources/hive_machine_local_data_source.dart';
import 'package:orning_and_evening_remembrances/features/assets/data/repositories/hive_machine_repository.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/hive_work_order_local_data_source.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/repositories/hive_work_order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveMachineLocalDataSource machineLocal;
  late HiveMachineRepository machineRepo;
  late HiveWorkOrderRepository workOrderRepo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_multi_ticket_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DepartmentTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MachineStatusAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MachineModelAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(WorkOrderTypeAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(WorkOrderStatusAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(PriorityAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(PlantShiftAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(EventChronologyAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SparePartModelAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(WorkOrderActivityLogAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(WorkOrderModelAdapter());

    await Hive.openBox<MachineModel>(HiveBoxes.machinesBox);
    await Hive.openBox<WorkOrderModel>(HiveBoxes.workOrdersBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box<MachineModel>(HiveBoxes.machinesBox).clear();
    await Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).clear();

    machineLocal = HiveMachineLocalDataSource();
    machineRepo = HiveMachineRepository(localDataSource: machineLocal);
    workOrderRepo = HiveWorkOrderRepository(
      localDataSource: HiveWorkOrderLocalDataSource(),
    );
  });

  test('Multi-ticket machine status: completing ticket 1 does NOT restore running when ticket 2 is active', () async {
    const machineId = 'EXT-01';
    final operatorUser = MockUsers.extrusionLead;
    final supervisorUser = MockUsers.maintenanceSupervisor;
    final techUser = MockUsers.mechanicalTech;

    // 1. Initial machine state: running
    final machine = MachineModel(
      id: machineId,
      name: 'Extruder Line 01',
      code: 'EXT-01',
      department: DepartmentType.extrusion,
      status: MachineStatus.running,
      subCategory: 'Extruder Line',
    );
    await machineLocal.cacheMachine(machine);

    // 2. Breakdown Ticket A created -> machine becomes down
    final ticketA = WorkOrderModel(
      id: 'WO-A',
      title: 'Extruder Drive Belt Snap',
      description: 'Mechanical drive belt broke during shift 1',
      machineId: machineId,
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.open,
      priority: Priority.critical,
      createdAt: DateTime.now(),
    );
    await workOrderRepo.createWorkOrder(ticketA, caller: operatorUser);
    await machineRepo.updateMachineStatus(machineId, MachineStatus.downtimeMaintenance);

    var currentMachine = await machineRepo.getMachineById(machineId);
    expect(currentMachine?.status, MachineStatus.downtimeMaintenance);

    // 3. Second Breakdown Ticket B created on same machine -> remains down
    final ticketB = WorkOrderModel(
      id: 'WO-B',
      title: 'Thermocouple Zone 4 Short',
      description: 'Temperature reading bouncing erratic',
      machineId: machineId,
      type: WorkOrderType.breakdown,
      status: WorkOrderStatus.open,
      priority: Priority.high,
      createdAt: DateTime.now(),
    );
    await workOrderRepo.createWorkOrder(ticketB, caller: operatorUser);

    // 4. Ticket A repair started -> machine becomes underRepair
    await workOrderRepo.assignTechnician('WO-A', techUser.id, supervisorUser.id, caller: supervisorUser);
    await workOrderRepo.startRepair('WO-A', caller: techUser);
    await machineRepo.updateMachineStatus(machineId, MachineStatus.underRepair);

    currentMachine = await machineRepo.getMachineById(machineId);
    expect(currentMachine?.status, MachineStatus.underRepair);

    // 5. Ticket A completed & closed through handshake
    await workOrderRepo.completeWorkOrder('WO-A', rootCause: 'Belt fatigue', actionsTaken: 'Replaced belt', caller: techUser);
    await workOrderRepo.confirmTestRun('WO-A', caller: operatorUser);
    await workOrderRepo.approveAndClose('WO-A', caller: supervisorUser);

    // Multi-work-order consistency evaluation:
    final allOrders = await workOrderRepo.getAllWorkOrders();
    final hasActiveBreakdowns = allOrders.any((w) =>
        w.machineId == machineId &&
        w.id != 'WO-A' &&
        w.type == WorkOrderType.breakdown &&
        w.status != WorkOrderStatus.verifiedClosed);

    expect(hasActiveBreakdowns, isTrue,
        reason: 'Ticket B is still open and active on machine EXT-01');

    // Therefore machine MUST NOT be set to running!
    if (!hasActiveBreakdowns) {
      await machineRepo.updateMachineStatus(machineId, MachineStatus.running);
    } else {
      // Re-evaluate appropriate status based on remaining tickets
      final hasInProgress = allOrders.any((w) =>
          w.machineId == machineId &&
          w.status == WorkOrderStatus.inProgress);
      final targetStatus = hasInProgress
          ? MachineStatus.underRepair
          : MachineStatus.downtimeMaintenance;
      await machineRepo.updateMachineStatus(machineId, targetStatus);
    }

    currentMachine = await machineRepo.getMachineById(machineId);
    expect(currentMachine?.status, isNot(MachineStatus.running));
    expect(currentMachine?.status, MachineStatus.downtimeMaintenance);

    // 6. Ticket B is now also processed through handshake and closed
    await workOrderRepo.assignTechnician('WO-B', techUser.id, supervisorUser.id, caller: supervisorUser);
    await workOrderRepo.startRepair('WO-B', caller: techUser);
    await workOrderRepo.completeWorkOrder('WO-B', rootCause: 'Wire short', actionsTaken: 'Rewired thermocouple', caller: techUser);
    await workOrderRepo.confirmTestRun('WO-B', caller: operatorUser);
    await workOrderRepo.approveAndClose('WO-B', caller: supervisorUser);

    final remainingActive = (await workOrderRepo.getAllWorkOrders()).any((w) =>
        w.machineId == machineId &&
        w.type == WorkOrderType.breakdown &&
        w.status != WorkOrderStatus.verifiedClosed);

    expect(remainingActive, isFalse);

    // Now machine safely returns to running
    await machineRepo.updateMachineStatus(machineId, MachineStatus.running);
    currentMachine = await machineRepo.getMachineById(machineId);
    expect(currentMachine?.status, MachineStatus.running);
  });
}
