import 'package:get_it/get_it.dart';

// Sync & Offline Core
import '../sync/network/network_connectivity_checker.dart';
import '../sync/outbox/outbox_local_data_source.dart';
import '../sync/outbox/outbox_sync_engine.dart';
import '../sync/delta/delta_sync_coordinator.dart';
import '../sync/realtime/supabase_realtime_sync_service.dart';

// Assets Feature
import '../../features/assets/data/datasources/hive_machine_local_data_source.dart';
import '../../features/assets/data/datasources/machine_local_data_source.dart';
import '../../features/assets/data/datasources/machine_remote_data_source.dart';
import '../../features/assets/data/datasources/supabase_machine_remote_data_source.dart';
import '../../features/assets/data/repositories/hive_machine_repository.dart';
import '../../features/assets/domain/repositories/machine_repository.dart';
import '../../features/assets/presentation/cubit/machine_cubit.dart';

// Downtime Feature
import '../../features/downtime/data/datasources/downtime_local_data_source.dart';
import '../../features/downtime/data/datasources/downtime_remote_data_source.dart';
import '../../features/downtime/data/datasources/supabase_downtime_remote_data_source.dart';
import '../../features/downtime/data/datasources/hive_downtime_local_data_source.dart';
import '../../features/downtime/data/repositories/hive_downtime_repository.dart';
import '../../features/downtime/domain/repositories/downtime_repository.dart';
import '../../features/downtime/presentation/cubit/downtime_cubit.dart';

// Work Orders Feature
import '../../features/work_orders/data/datasources/hive_work_order_local_data_source.dart';
import '../../features/work_orders/data/datasources/work_order_local_data_source.dart';
import '../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../features/work_orders/data/datasources/supabase_work_order_remote_data_source.dart';
import '../../features/work_orders/data/repositories/hive_work_order_repository.dart';
import '../../features/work_orders/domain/repositories/work_order_repository.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';

// Auth Feature
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---------------------------------------------------------------------------
  // Offline-First Outbox & Network Sync Services
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<NetworkConnectivityChecker>(
    () => DefaultNetworkConnectivityChecker(),
  );

  getIt.registerLazySingleton<OutboxLocalDataSource>(
    () => HiveOutboxLocalDataSource(),
  );

  // ---------------------------------------------------------------------------
  // Auth Repository (Supabase)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(),
  );

  // ---------------------------------------------------------------------------
  // DataSources: Local (Hive Cache) & Remote (Supabase Sync)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<MachineLocalDataSource>(
    () => HiveMachineLocalDataSource(),
  );
  getIt.registerLazySingleton<MachineRemoteDataSource>(
    () => SupabaseMachineRemoteDataSource(),
  );

  getIt.registerLazySingleton<DowntimeLocalDataSource>(
    () => HiveDowntimeLocalDataSource(),
  );
  getIt.registerLazySingleton<DowntimeRemoteDataSource>(
    () => SupabaseDowntimeRemoteDataSource(),
  );

  getIt.registerLazySingleton<WorkOrderLocalDataSource>(
    () => HiveWorkOrderLocalDataSource(),
  );
  getIt.registerLazySingleton<WorkOrderRemoteDataSource>(
    () => SupabaseWorkOrderRemoteDataSource(),
  );

  // ---------------------------------------------------------------------------
  // Outbox Engine & Delta / Realtime Coordinators
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<OutboxSyncEngine>(
    () => OutboxSyncEngine(
      outboxLocal: getIt<OutboxLocalDataSource>(),
      workOrderRemote: getIt<WorkOrderRemoteDataSource>(),
      downtimeRemote: getIt<DowntimeRemoteDataSource>(),
      networkChecker: getIt<NetworkConnectivityChecker>(),
    ),
  );

  getIt.registerLazySingleton<DeltaSyncCoordinator>(
    () => DeltaSyncCoordinator(
      workOrderRemote: getIt<WorkOrderRemoteDataSource>(),
      downtimeRemote: getIt<DowntimeRemoteDataSource>(),
      machineRemote: getIt<MachineRemoteDataSource>(),
      outboxLocal: getIt<OutboxLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<SupabaseRealtimeSyncService>(
    () => SupabaseRealtimeSyncService(
      outboxLocal: getIt<OutboxLocalDataSource>(),
      networkChecker: getIt<NetworkConnectivityChecker>(),
      deltaSyncCoordinator: getIt<DeltaSyncCoordinator>(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Repositories (Injecting DataSources + OutboxSyncEngine)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<MachineRepository>(
    () => HiveMachineRepository(
      localDataSource: getIt<MachineLocalDataSource>(),
      remoteDataSource: getIt<MachineRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<DowntimeRepository>(
    () => HiveDowntimeRepository(
      localDataSource: getIt<DowntimeLocalDataSource>(),
      remoteDataSource: getIt<DowntimeRemoteDataSource>(),
      syncEngine: getIt<OutboxSyncEngine>(),
    ),
  );

  getIt.registerLazySingleton<WorkOrderRepository>(
    () => HiveWorkOrderRepository(
      localDataSource: getIt<WorkOrderLocalDataSource>(),
      remoteDataSource: getIt<WorkOrderRemoteDataSource>(),
      syncEngine: getIt<OutboxSyncEngine>(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Cubits / Presentation Layer
  // ---------------------------------------------------------------------------
  getIt.registerFactory<MachineCubit>(
    () => MachineCubit(getIt<MachineRepository>()),
  );

  getIt.registerFactory<DowntimeCubit>(
    () => DowntimeCubit(
      downtimeRepository: getIt<DowntimeRepository>(),
      machineRepository: getIt<MachineRepository>(),
    ),
  );

  getIt.registerFactory<WorkOrderCubit>(
    () => WorkOrderCubit(getIt<WorkOrderRepository>()),
  );
}
