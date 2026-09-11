import '../../domain/models/work_order_model.dart';
import '../../domain/enums/work_order_status.dart';

/// Abstract contract for work order local persistence (Hive).
///
/// Implementations handle CRUD operations against the local cache.
/// This interface enables swapping the storage engine without
/// touching the Repository or Cubit layers.
abstract class WorkOrderLocalDataSource {
  /// Returns all cached work orders.
  Future<List<WorkOrderModel>> getAllWorkOrders();

  /// Returns a single work order by [id], or null if not found.
  Future<WorkOrderModel?> getWorkOrderById(String id);

  /// Returns work orders matching the given [status].
  Future<List<WorkOrderModel>> getWorkOrdersByStatus(WorkOrderStatus status);

  /// Returns work orders assigned to a specific [technicianId].
  Future<List<WorkOrderModel>> getWorkOrdersForTechnician(String technicianId);

  /// Persists a [workOrder] to the local cache. Upserts by ID.
  Future<void> cacheWorkOrder(WorkOrderModel workOrder);

  /// Persists a batch of work orders to the local cache.
  Future<void> cacheWorkOrders(List<WorkOrderModel> workOrders);

  /// Deletes a work order from the local cache by [id].
  Future<void> deleteWorkOrder(String id);

  /// Clears all work orders from the local cache.
  Future<void> clearAll();
}
