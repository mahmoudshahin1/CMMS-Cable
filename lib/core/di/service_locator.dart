import 'package:get_it/get_it.dart';

// Assets Feature
import '../../features/assets/data/datasources/hive_machine_local_data_source.dart';
import '../../features/assets/data/datasources/machine_local_data_source.dart';
import '../../features/assets/data/datasources/machine_remote_data_source.dart';
import '../../features/assets/data/repositories/hive_machine_repository.dart';
import '../../features/assets/domain/repositories/machine_repository.dart';
import '../../features/assets/presentation/cubit/machine_cubit.dart';

// Downtime Feature
import '../../features/downtime/data/datasources/downtime_local_data_source.dart';
import '../../features/downtime/data/datasources/downtime_remote_data_source.dart';
import '../../features/downtime/data/datasources/hive_downtime_local_data_source.dart';
import '../../features/downtime/data/repositories/hive_downtime_repository.dart';
import '../../features/downtime/domain/repositories/downtime_repository.dart';
import '../../features/downtime/presentation/cubit/downtime_cubit.dart';

// Work Orders Feature
import '../../features/work_orders/data/datasources/hive_work_order_local_data_source.dart';
import '../../features/work_orders/data/datasources/work_order_local_data_source.dart';
import '../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import '../../features/work_orders/data/repositories/hive_work_order_repository.dart';
import '../../features/work_orders/domain/repositories/work_order_repository.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---------------------------------------------------------------------------
  // DataSources: Local (Hive Cache) & Remote (Supabase Sync)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<MachineLocalDataSource>(
    () => HiveMachineLocalDataSource(),
  );
  getIt.registerLazySingleton<MachineRemoteDataSource>(
    () => const SupabaseMachineRemoteDataSourceStub(),
  );

  getIt.registerLazySingleton<DowntimeLocalDataSource>(
    () => HiveDowntimeLocalDataSource(),
  );
  getIt.registerLazySingleton<DowntimeRemoteDataSource>(
    () => const SupabaseDowntimeRemoteDataSourceStub(),
  );

  getIt.registerLazySingleton<WorkOrderLocalDataSource>(
    () => HiveWorkOrderLocalDataSource(),
  );
  getIt.registerLazySingleton<WorkOrderRemoteDataSource>(
    () => const SupabaseWorkOrderRemoteDataSourceStub(),
  );

  // ---------------------------------------------------------------------------
  // Repositories (Injecting DataSources)
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
    ),
  );

  getIt.registerLazySingleton<WorkOrderRepository>(
    () => HiveWorkOrderRepository(
      localDataSource: getIt<WorkOrderLocalDataSource>(),
      remoteDataSource: getIt<WorkOrderRemoteDataSource>(),
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
