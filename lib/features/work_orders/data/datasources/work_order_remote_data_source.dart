import '../../domain/models/work_order_model.dart';

/// Abstract contract for remote work order persistence (e.g. Supabase).
abstract class WorkOrderRemoteDataSource {
  /// Fetches all work orders from the remote backend.
  Future<List<WorkOrderModel>> fetchWorkOrders();

  /// Fetches a single work order by [id] from the remote backend.
  Future<WorkOrderModel?> fetchWorkOrderById(String id);

  /// Pushes a work order to the remote backend.
  Future<void> syncWorkOrder(WorkOrderModel workOrder);

  /// Deletes a work order from the remote backend.
  Future<void> deleteRemoteWorkOrder(String id);
}

/// Offline-first fallback / stub for [WorkOrderRemoteDataSource].
class SupabaseWorkOrderRemoteDataSourceStub
    implements WorkOrderRemoteDataSource {
  const SupabaseWorkOrderRemoteDataSourceStub();

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => const [];

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async => null;

  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {
    // Queued for background sync when Supabase is online
  }

  @override
  Future<void> deleteRemoteWorkOrder(String id) async {
    // Queued for background sync
  }
}
