import '../models/work_order_model.dart';
import '../models/spare_part_model.dart';
import '../enums/work_order_status.dart';
import '../../../auth/domain/models/user_model.dart';

abstract class WorkOrderRepository {
  Future<List<WorkOrderModel>> getAllWorkOrders();
  Future<WorkOrderModel?> getWorkOrderById(String id);
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(WorkOrderStatus status);
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(String technicianId);
  Future<WorkOrderModel> createWorkOrder(WorkOrderModel workOrder, {UserModel? caller});
  Future<void> updateWorkOrderStatus(String workOrderId, WorkOrderStatus status, {UserModel? caller});
  Future<void> assignTechnician(String workOrderId, String technicianId, String supervisorId, {UserModel? caller});
  Future<void> startRepair(String workOrderId, {required UserModel caller});
  Future<void> addSparePart(String workOrderId, SparePartModel sparePart, {UserModel? caller});
  Future<void> completeWorkOrder(
    String workOrderId, {
    required String rootCause,
    required String actionsTaken,
    UserModel? caller,
  });
  Future<void> confirmTestRun(String workOrderId, {required UserModel caller});
  Future<void> approveAndClose(String workOrderId, {required UserModel caller});
}
