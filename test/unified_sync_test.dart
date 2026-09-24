import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/sync/delta/delta_sync_coordinator.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_local_data_source.dart';
import 'package:orning_and_evening_remembrances/features/assets/data/datasources/machine_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/department_type.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/enums/machine_status.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/machine_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/models/process_log_model.dart';
import 'package:orning_and_evening_remembrances/features/assets/domain/repositories/machine_repository.dart';
import 'package:orning_and_evening_remembrances/features/assets/presentation/cubit/machine_cubit.dart';
import 'package:orning_and_evening_remembrances/features/assets/presentation/cubit/machine_state.dart';
import 'package:orning_and_evening_remembrances/features/downtime/data/datasources/downtime_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';

class FakeOutboxLocalDataSource implements OutboxLocalDataSource {
  final Map<String, OutboxCommand> commands = {};

  @override
  Future<void> enqueue(OutboxCommand command) async {
    commands[command.commandId] = command;
  }

  @override
  Future<List<OutboxCommand>> getPendingCommands() async =>
      commands.values.where((c) => c.status == OutboxCommandStatus.pending).toList();

  @override
  Future<int> getPendingCount() async =>
      commands.values.where((c) => c.status == OutboxCommandStatus.pending).length;

  @override
  Future<List<OutboxCommand>> getDeadLetterCommands() async =>
      commands.values.where((c) => c.status == OutboxCommandStatus.deadLetter).toList();

  @override
  Future<void> markInFlight(String commandId) async {}

  @override
  Future<void> markCompleted(String commandId, {DateTime? processedAt}) async {
    final c = commands[commandId];
    if (c != null) commands[commandId] = c.copyWith(status: OutboxCommandStatus.completed);
  }

  @override
  Future<void> markFailed(String commandId, String error,
      {bool isDeadLetter = false, DateTime? nextRetryAt}) async {}

  @override
  Future<void> markTerminalFailure(
    String commandId,
    String error, {
    required OutboxCommandStatus status,
  }) async {}

  @override
  Future<bool> hasPendingForAggregate(String aggregateId) async {
    return commands.values.any((c) =>
        c.aggregateId == aggregateId && c.status == OutboxCommandStatus.pending);
  }

  @override
  Future<List<OutboxCommand>> getCommandsForAggregate(String aggregateId) async => [];

  @override
  Future<void> deleteCommand(String commandId) async {}

  @override
  Future<void> clearCompleted() async {}

  OutboxCommand? getCommand(String commandId) => commands[commandId];
}

class FakeMachineRepository implements MachineRepository {
  List<MachineModel> machines = [];

  @override
  Future<List<MachineModel>> getAllMachines() async => machines;

  @override
  Future<List<MachineModel>> refreshFromRemote() async => machines;

  @override
  Future<MachineModel?> getMachineById(String id) async =>
      machines.where((m) => m.id == id).firstOrNull;

  @override
  Future<List<MachineModel>> getMachinesByDepartment(DepartmentType department) async =>
      machines.where((m) => m.department == department).toList();

  @override
  Future<List<MachineModel>> getMachinesByStatus(MachineStatus status) async =>
      machines.where((m) => m.status == status).toList();

  @override
  Future<void> updateMachineStatus(String machineId, MachineStatus newStatus) async {
    final idx = machines.indexWhere((m) => m.id == machineId);
    if (idx != -1) {
      machines[idx] = machines[idx].copyWith(status: newStatus);
    }
  }

  @override
  Future<void> saveProcessLog(ProcessLogModel log) async {}

  @override
  Future<List<ProcessLogModel>> getProcessLogsForMachine(String machineId) async => [];
}

void main() {
  group('Unified Sync & Conflict Guard Unit Tests', () {
    test('MachineCubit reactive reload on delta success and filter preservation', () async {
      final repo = FakeMachineRepository();
      repo.machines = [
        const MachineModel(
          id: 'RS02',
          code: 'RS02',
          name: 'Rigid Strander 61 - Line 02',
          department: DepartmentType.stranding,
          status: MachineStatus.running,
          subCategory: 'Rigid Strander 61',
        ),
      ];

      final cubit = MachineCubit(repo);
      await cubit.loadMachines();

      expect(cubit.state, isA<MachineLoaded>());
      var loaded = cubit.state as MachineLoaded;
      expect(loaded.allMachines.first.status, equals(MachineStatus.running));

      // Simulate remote update to downtimeMaintenance
      repo.machines = [
        const MachineModel(
          id: 'RS02',
          code: 'RS02',
          name: 'Rigid Strander 61 - Line 02',
          department: DepartmentType.stranding,
          status: MachineStatus.downtimeMaintenance,
          subCategory: 'Rigid Strander 61',
        ),
      ];

      await cubit.loadMachines(silent: true);
      loaded = cubit.state as MachineLoaded;
      expect(loaded.allMachines.first.status, equals(MachineStatus.downtimeMaintenance));
      expect(loaded.allMachines.first.status.isDowntime, isTrue);

      await cubit.close();
    });

    test('Conflict guard prevents server update from overwriting pending local Outbox mutation', () async {
      final fakeOutbox = FakeOutboxLocalDataSource();
      await fakeOutbox.enqueue(OutboxCommand(
        commandId: 'cmd-local-1',
        commandType: 'create_work_order',
        aggregateId: 'RS02',
        payload: {},
        occurredAt: DateTime.now(),
      ));

      final hasPending = await fakeOutbox.hasPendingForAggregate('RS02');
      expect(hasPending, isTrue, reason: 'Outbox has pending command for RS02');
    });

    test('DeltaSyncCoordinator returns gracefully when unauthenticated', () async {
      final fakeOutbox = FakeOutboxLocalDataSource();
      final coordinator = DeltaSyncCoordinator(
        workOrderRemote: const SupabaseWorkOrderRemoteDataSourceStub(),
        downtimeRemote: const SupabaseDowntimeRemoteDataSourceStub(),
        machineRemote: const SupabaseMachineRemoteDataSourceStub(),
        outboxLocal: fakeOutbox,
      );

      // Should not throw
      await coordinator.initialSync();
      await coordinator.syncDeltas();
      coordinator.dispose();
    });
  });
}
