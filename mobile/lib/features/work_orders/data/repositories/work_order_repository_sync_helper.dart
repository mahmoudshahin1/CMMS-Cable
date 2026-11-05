import 'package:hive/hive.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/sync/outbox/outbox_command.dart';
import '../../../../core/sync/outbox/outbox_sync_engine.dart';
import '../../../assets/domain/models/machine_model.dart';
import '../../domain/models/work_order_model.dart';
import '../datasources/work_order_local_data_source.dart';
import '../datasources/work_order_remote_data_source.dart';

/// Helper handling local caching, sync engine triggers, and machine lookups.
class WorkOrderRepositorySyncHelper {
  static MachineModel? findMachine(String machineId) {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.machinesBox)) return null;
      final box = Hive.box<MachineModel>(HiveBoxes.machinesBox);
      final mid = machineId.toLowerCase();
      return box.get(machineId) ??
          box.values.cast<MachineModel?>().firstWhere(
                (m) => m?.id.toLowerCase() == mid || m?.code.toLowerCase() == mid,
                orElse: () => null,
              );
    } catch (_) {
      return null;
    }
  }

  static Future<void> persistAndSync({
    required WorkOrderModel updated,
    required WorkOrderLocalDataSource localDataSource,
    WorkOrderRemoteDataSource? remoteDataSource,
    OutboxSyncEngine? syncEngine,
    OutboxCommand? command,
  }) async {
    await localDataSource.cacheWorkOrder(updated);
    remoteDataSource?.syncWorkOrder(updated);
    if (command != null) {
      syncEngine?.enqueueAndTrigger(command);
    }
  }
}

