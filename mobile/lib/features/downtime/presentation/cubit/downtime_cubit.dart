import 'package:flutter_bloc/flutter_bloc.dart';
import 'downtime_state.dart';
import '../../domain/repositories/downtime_repository.dart';
import '../../../assets/domain/repositories/machine_repository.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../domain/enums/downtime_category.dart';
import '../../../assets/domain/enums/machine_status.dart';

class DowntimeCubit extends Cubit<DowntimeState> {
  final DowntimeRepository downtimeRepository;
  final MachineRepository machineRepository;

  DowntimeCubit({
    required this.downtimeRepository,
    required this.machineRepository,
  }) : super(DowntimeInitial());

  Future<void> loadDowntimeLogs() async {
    emit(DowntimeLoading());
    try {
      final all = await downtimeRepository.getAllDowntimeLogs();
      final active = await downtimeRepository.getActiveDowntimeLogs();
      emit(DowntimeLoaded(allLogs: all, activeLogs: active));
    } catch (e) {
      emit(DowntimeError('Failed to load downtime logs: ${e.toString()}'));
    }
  }

  Future<void> reportDowntime(DowntimeLogModel log) async {
    try {
      await downtimeRepository.createDowntimeLog(log);

      // Automatically set machine status according to category
      final newStatus = log.category.isMaintenance
          ? MachineStatus.downtimeMaintenance
          : MachineStatus.downtimeProcess;

      await machineRepository.updateMachineStatus(log.machineId, newStatus);
      await loadDowntimeLogs();
    } catch (e) {
      emit(DowntimeError('Failed to report downtime: ${e.toString()}'));
    }
  }

  Future<void> endDowntime(String logId, String machineId, {String? comments}) async {
    try {
      await downtimeRepository.endDowntime(logId, comments: comments);
      // Restore machine to running or idle
      await machineRepository.updateMachineStatus(machineId, MachineStatus.running);
      await loadDowntimeLogs();
    } catch (e) {
      emit(DowntimeError('Failed to end downtime: ${e.toString()}'));
    }
  }
}
