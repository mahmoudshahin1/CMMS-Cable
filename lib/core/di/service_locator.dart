import 'package:get_it/get_it.dart';
import '../../features/assets/domain/repositories/machine_repository.dart';
import '../../features/assets/data/repositories/hive_machine_repository.dart';
import '../../features/downtime/domain/repositories/downtime_repository.dart';
import '../../features/downtime/data/repositories/hive_downtime_repository.dart';
import '../../features/work_orders/domain/repositories/work_order_repository.dart';
import '../../features/work_orders/data/repositories/hive_work_order_repository.dart';
import '../../features/assets/presentation/cubit/machine_cubit.dart';
import '../../features/downtime/presentation/cubit/downtime_cubit.dart';
import '../../features/work_orders/presentation/cubit/work_order_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Repositories
  getIt.registerLazySingleton<MachineRepository>(
      () => HiveMachineRepository());
  getIt.registerLazySingleton<DowntimeRepository>(
      () => HiveDowntimeRepository());
  getIt.registerLazySingleton<WorkOrderRepository>(
      () => HiveWorkOrderRepository());

  // Cubits
  getIt.registerFactory<MachineCubit>(
      () => MachineCubit(getIt<MachineRepository>()));
  getIt.registerFactory<DowntimeCubit>(
      () => DowntimeCubit(
            downtimeRepository: getIt<DowntimeRepository>(),
            machineRepository: getIt<MachineRepository>(),
          ));
  getIt.registerFactory<WorkOrderCubit>(
      () => WorkOrderCubit(getIt<WorkOrderRepository>()));
}
