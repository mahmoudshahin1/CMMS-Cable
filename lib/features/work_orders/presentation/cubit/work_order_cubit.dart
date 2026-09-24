import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'work_order_state.dart';
import '../../domain/repositories/work_order_repository.dart';
import '../../domain/models/work_order_model.dart';
import '../../domain/models/spare_part_model.dart';
import '../../domain/enums/work_order_status.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/errors/security_exceptions.dart';
import '../../../../core/sync/models/sync_status.dart';
import '../../../../core/sync/realtime/supabase_realtime_sync_service.dart';
import '../../../../core/sync/delta/delta_sync_coordinator.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';

class WorkOrderCubit extends Cubit<WorkOrderState> {
  final WorkOrderRepository repository;
  final SupabaseRealtimeSyncService? realtimeSync;
  final DeltaSyncCoordinator? deltaSync;
  final OutboxSyncEngine? syncEngine;

  StreamSubscription<String>? _realtimeSub;
  StreamSubscription<SyncStatus>? _deltaSub;
  StreamSubscription<OutboxTerminalFailure>? _terminalFailureSub;

  WorkOrderCubit(
    this.repository, {
    this.realtimeSync,
    this.deltaSync,
    this.syncEngine,
  }) : super(WorkOrderInitial()) {
    _initSyncSubscriptions();
  }

  void _initSyncSubscriptions() {
    _realtimeSub = realtimeSync?.onRealtimeChange.listen((event) {
      if (event.startsWith('work_orders:')) {
        loadWorkOrders(silent: true);
      }
    });

    _deltaSub = deltaSync?.statusStream.listen((status) {
      if (status.state == SyncState.success) {
        loadWorkOrders(silent: true);
      }
    });

    _terminalFailureSub = syncEngine?.terminalFailureStream.listen((failure) {
      if (failure.command.commandType.endsWith('_work_order') ||
          failure.command.commandType.endsWith('_part') ||
          failure.command.commandType.contains('test_run')) {
        emit(WorkOrderError(
          failure.userMessage,
          previousWorkOrders: _currentOrders,
        ));
        loadWorkOrders(silent: true);
      }
    });
  }

  Future<void> loadWorkOrders({bool silent = false}) async {
    final previousOrders = state is WorkOrderLoaded
        ? (state as WorkOrderLoaded).allWorkOrders
        : <WorkOrderModel>[];

    if (!silent) {
      emit(WorkOrderLoading());
    }
    try {
      final all = await repository.getAllWorkOrders();
      final active = all.where((w) => w.status.isActive).toList();
      emit(WorkOrderLoaded(allWorkOrders: all, activeWorkOrders: active));
    } catch (e) {
      emit(WorkOrderError(
        'Failed to load work orders: ${e.toString()}',
        previousWorkOrders: previousOrders,
      ));
    }
  }

  List<WorkOrderModel> get _currentOrders {
    if (state is WorkOrderLoaded) {
      return (state as WorkOrderLoaded).allWorkOrders;
    } else if (state is WorkOrderError) {
      return (state as WorkOrderError).previousWorkOrders;
    }
    return const [];
  }

  Future<void> createWorkOrder(WorkOrderModel workOrder,
      {UserModel? caller}) async {
    try {
      await repository.createWorkOrder(workOrder, caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to create work order: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> assignTechnician(
      String workOrderId, String technicianId, String supervisorId,
      {UserModel? caller, String? technicianName}) async {
    try {
      await repository.assignTechnician(
        workOrderId,
        technicianId,
        supervisorId,
        caller: caller,
        technicianName: technicianName,
      );
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to assign technician: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> startRepair(String workOrderId,
      {required UserModel caller}) async {
    try {
      await repository.startRepair(workOrderId, caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to start repair: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> updateStatus(
      String workOrderId, WorkOrderStatus status,
      {UserModel? caller}) async {
    try {
      await repository.updateWorkOrderStatus(workOrderId, status,
          caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to update status: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> addSparePart(
      String workOrderId, SparePartModel sparePart,
      {UserModel? caller}) async {
    try {
      await repository.addSparePart(workOrderId, sparePart, caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to add spare part: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> completeWorkOrder(
    String workOrderId, {
    required String rootCause,
    required String actionsTaken,
    UserModel? caller,
  }) async {
    try {
      await repository.completeWorkOrder(
        workOrderId,
        rootCause: rootCause,
        actionsTaken: actionsTaken,
        caller: caller,
      );
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to complete work order: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> confirmTestRun(String workOrderId,
      {required UserModel caller}) async {
    try {
      await repository.confirmTestRun(workOrderId, caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to confirm test run: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  Future<void> approveAndClose(String workOrderId,
      {required UserModel caller}) async {
    try {
      await repository.approveAndClose(workOrderId, caller: caller);
      await loadWorkOrders(silent: true);
    } on SecurityException catch (e) {
      emit(WorkOrderError(e.message, previousWorkOrders: _currentOrders));
    } catch (e) {
      emit(WorkOrderError('Failed to approve and close: ${e.toString()}',
          previousWorkOrders: _currentOrders));
    }
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    _deltaSub?.cancel();
    _terminalFailureSub?.cancel();
    return super.close();
  }
}
