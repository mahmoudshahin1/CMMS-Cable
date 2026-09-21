import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/domain/models/work_order_activity_log.dart';
import '../../../features/work_orders/domain/models/spare_part_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';

/// Reconciles optimistic lock collisions (VERSION_MISMATCH / P0001)
/// by fetching the latest authoritative server record and merging local activity logs.
class WorkOrderConflictResolver {
  static Future<WorkOrderModel?> resolveVersionConflict({
    required String workOrderId,
    required WorkOrderRemoteDataSource remoteDataSource,
    required Box<WorkOrderModel> localBox,
  }) async {
    debugPrint('🔄 ConflictResolver: resolving version collision on $workOrderId');

    final serverWo = await remoteDataSource.fetchWorkOrderById(workOrderId);
    if (serverWo == null) {
      debugPrint('⚠️ ConflictResolver: work order $workOrderId not found on server');
      return null;
    }

    final localWo = localBox.get(workOrderId);
    if (localWo == null) {
      await localBox.put(workOrderId, serverWo);
      return serverWo;
    }

    // Merge activity logs (preserve unique steps from both client and server)
    final existingLogIds = serverWo.activityLogs.map((l) => l.id).toSet();
    final mergedLogs = <WorkOrderActivityLog>[...serverWo.activityLogs];

    for (final localLog in localWo.activityLogs) {
      if (localLog.id.isNotEmpty && !existingLogIds.contains(localLog.id)) {
        mergedLogs.add(localLog);
      }
    }
    mergedLogs.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Merge spare parts (prevent duplicate part insertions by part number)
    final existingPartCodes =
        serverWo.spareParts.map((p) => p.partNumber).toSet();
    final mergedParts = <SparePartModel>[...serverWo.spareParts];

    for (final localPart in localWo.spareParts) {
      if (!existingPartCodes.contains(localPart.partNumber)) {
        mergedParts.add(localPart);
      }
    }

    final reconciled = serverWo.copyWith(
      activityLogs: mergedLogs,
      spareParts: mergedParts,
    );

    await localBox.put(workOrderId, reconciled);
    debugPrint('✅ ConflictResolver: reconciled WorkOrder $workOrderId successfully');
    return reconciled;
  }
}
