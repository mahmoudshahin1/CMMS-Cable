import 'package:hive/hive.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../domain/enums/work_order_status.dart';
import '../../domain/models/work_order_model.dart';
import 'work_order_local_data_source.dart';

/// Hive implementation of [WorkOrderLocalDataSource].
///
/// Encapsulates direct Hive box operations for work orders.
class HiveWorkOrderLocalDataSource implements WorkOrderLocalDataSource {
  Box<WorkOrderModel> get _box =>
      Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);

  @override
  Future<List<WorkOrderModel>> getAllWorkOrders() async {
    return _box.values.toList();
  }

  @override
  Future<WorkOrderModel?> getWorkOrderById(String id) async {
    return _box.get(id);
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(
      WorkOrderStatus status) async {
    return _box.values.where((wo) => wo.status == status).toList();
  }

  @override
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(
      String technicianId) async {
    return _box.values
        .where((wo) => wo.assignedToTechnicianId == technicianId)
        .toList();
  }

  @override
  Future<void> cacheWorkOrder(WorkOrderModel workOrder) async {
    await _box.put(workOrder.id, workOrder);
  }

  @override
  Future<void> cacheWorkOrders(List<WorkOrderModel> workOrders) async {
    final map = {for (final wo in workOrders) wo.id: wo};
    await _box.putAll(map);
  }

  @override
  Future<void> deleteWorkOrder(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
