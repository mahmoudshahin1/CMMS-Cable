import '../../features/assets/domain/models/machine_model.dart';
import '../../features/work_orders/domain/models/work_order_model.dart';
import 'drawing_stranding_machines.dart';
import 'extrusion_ccv_machines.dart';
import 'assembly_armouring_machines.dart';
import 'initial_work_orders.dart';

class FactorySeedData {
  static List<MachineModel> getInitialMachines() {
    return [
      ...drawingStrandingMachines,
      ...extrusionCcvMachines,
      ...assemblyArmouringMachines,
    ];
  }

  static List<WorkOrderModel> getInitialWorkOrders() {
    return getInitialWorkOrdersList();
  }
}
