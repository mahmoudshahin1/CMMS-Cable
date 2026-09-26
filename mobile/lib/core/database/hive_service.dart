import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';
import 'adapters/enum_adapters.dart';
import 'adapters/model_adapters.dart';
import '../seed/factory_seed_data.dart';
import '../../features/assets/domain/models/machine_model.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/downtime/domain/models/downtime_log_model.dart';
import '../../features/work_orders/domain/models/work_order_model.dart';
import '../../features/assets/domain/models/process_log_model.dart';
import '../sync/outbox/outbox_command.dart';
import '../auth/user_directory_helper.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Enum Adapters
    Hive.registerAdapter(UserRoleAdapter());
    Hive.registerAdapter(DepartmentTypeAdapter());
    Hive.registerAdapter(MachineStatusAdapter());
    Hive.registerAdapter(DowntimeCategoryAdapter());
    Hive.registerAdapter(WorkOrderTypeAdapter());
    Hive.registerAdapter(WorkOrderStatusAdapter());
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(PlantShiftAdapter());
    Hive.registerAdapter(OutboxCommandStatusAdapter());

    // Register Model Adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(MachineModelAdapter());
    Hive.registerAdapter(ProcessLogModelAdapter());
    Hive.registerAdapter(DowntimeLogModelAdapter());
    Hive.registerAdapter(SparePartModelAdapter());
    Hive.registerAdapter(WorkOrderModelAdapter());
    Hive.registerAdapter(WorkOrderActivityLogAdapter());
    Hive.registerAdapter(EventChronologyAdapter());
    Hive.registerAdapter(OutboxCommandAdapter());

    // Open Boxes
    final machinesBox = await Hive.openBox<MachineModel>(HiveBoxes.machinesBox);
    final usersBox = await Hive.openBox<UserModel>(HiveBoxes.usersBox);
    await Hive.openBox<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);
    final workOrdersBox = await Hive.openBox<WorkOrderModel>(HiveBoxes.workOrdersBox);
    await Hive.openBox<ProcessLogModel>(HiveBoxes.processLogsBox);
    await Hive.openBox(HiveBoxes.settingsBox);
    await Hive.openBox<OutboxCommand>(HiveBoxes.outboxCommandsBox);

    // Populate initial factory machines seed data if empty
    if (machinesBox.isEmpty) {
      final initialMachines = FactorySeedData.getInitialMachines();
      for (final machine in initialMachines) {
        await machinesBox.put(machine.id, machine);
      }
    }

    // Ensure all standard users & technicians exist in usersBox
    final initialUsers = FactorySeedData.getInitialUsers();
    for (final user in initialUsers) {
      if (!usersBox.containsKey(user.id)) {
        await usersBox.put(user.id, user);
      }
    }
    UserDirectoryHelper.registerUsers(usersBox.values);

    // Populate initial factory work orders seed data
    if (workOrdersBox.isEmpty) {
      final initialOrders = FactorySeedData.getInitialWorkOrders();
      for (final order in initialOrders) {
        await workOrdersBox.put(order.id, order);
      }
    } else if (!workOrdersBox.containsKey('WO-ELEC-001')) {
      final initialOrders = FactorySeedData.getInitialWorkOrders();
      for (final order in initialOrders) {
        if (!workOrdersBox.containsKey(order.id)) {
          await workOrdersBox.put(order.id, order);
        }
      }
    }
  }
}
