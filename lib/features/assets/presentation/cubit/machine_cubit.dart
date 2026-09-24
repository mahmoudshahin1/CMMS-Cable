import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'machine_state.dart';
import '../../domain/repositories/machine_repository.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/process_log_model.dart';
import '../../../../core/sync/models/sync_status.dart';
import '../../../../core/sync/realtime/supabase_realtime_sync_service.dart';
import '../../../../core/sync/delta/delta_sync_coordinator.dart';

class MachineCubit extends Cubit<MachineState> {
  final MachineRepository repository;
  final SupabaseRealtimeSyncService? realtimeSync;
  final DeltaSyncCoordinator? deltaSync;

  StreamSubscription<String>? _realtimeSub;
  StreamSubscription<SyncStatus>? _deltaSub;

  MachineCubit(
    this.repository, {
    this.realtimeSync,
    this.deltaSync,
  }) : super(MachineInitial()) {
    _initSyncSubscriptions();
  }

  void _initSyncSubscriptions() {
    _realtimeSub = realtimeSync?.onRealtimeChange.listen((event) {
      if (event.startsWith('machines:')) {
        loadMachines(silent: true);
      }
    });

    _deltaSub = deltaSync?.statusStream.listen((status) {
      if (status.state == SyncState.success) {
        loadMachines(silent: true);
      }
    });
  }

  Future<void> loadMachines({bool forceRemote = false, bool silent = false}) async {
    final currentState = state;
    DepartmentType? currentDept;
    MachineStatus? currentStatus;

    if (currentState is MachineLoaded) {
      currentDept = currentState.selectedDepartment;
      currentStatus = currentState.selectedStatusFilter;
    }

    if (!silent) {
      emit(MachineLoading());
    }

    try {
      final machines = forceRemote
          ? await repository.refreshFromRemote()
          : await repository.getAllMachines();

      final filtered = _applyFilters(machines, currentDept, currentStatus);

      emit(MachineLoaded(
        allMachines: machines,
        filteredMachines: filtered,
        selectedDepartment: currentDept,
        selectedStatusFilter: currentStatus,
      ));
    } catch (e) {
      emit(MachineError('Failed to load machines: ${e.toString()}'));
    }
  }

  void filterByDepartment(DepartmentType? department) {
    if (state is MachineLoaded) {
      final current = state as MachineLoaded;
      emit(current.copyWith(
        filteredMachines: _applyFilters(
          current.allMachines,
          department,
          current.selectedStatusFilter,
        ),
        selectedDepartment: department,
      ));
    }
  }

  void filterByStatus(MachineStatus? status) {
    if (state is MachineLoaded) {
      final current = state as MachineLoaded;
      emit(current.copyWith(
        filteredMachines: _applyFilters(
          current.allMachines,
          current.selectedDepartment,
          status,
        ),
        selectedStatusFilter: status,
      ));
    }
  }

  List<MachineModel> _applyFilters(
    List<MachineModel> all,
    DepartmentType? dept,
    MachineStatus? status,
  ) {
    return all.where((m) {
      final matchesDept = dept == null || m.department == dept;
      final matchesStatus = status == null || m.status == status;
      return matchesDept && matchesStatus;
    }).toList();
  }

  Future<void> updateMachineStatus(String machineId, MachineStatus newStatus) async {
    try {
      await repository.updateMachineStatus(machineId, newStatus);
      await loadMachines(silent: true);
    } catch (e) {
      emit(MachineError('Failed to update machine status: ${e.toString()}'));
    }
  }

  Future<void> logRunningParameters(ProcessLogModel log) async {
    try {
      await repository.saveProcessLog(log);
      await loadMachines(silent: true);
    } catch (e) {
      emit(MachineError('Failed to log process parameters: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    _deltaSub?.cancel();
    return super.close();
  }
}
