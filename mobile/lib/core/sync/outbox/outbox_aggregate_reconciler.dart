import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../database/hive_boxes.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';

/// Replaces local aggregate state with server authority after a command resolves.
class OutboxAggregateReconciler {
  static Future<void> reconcile({
    required String aggregateId,
    required String commandType,
    required WorkOrderRemoteDataSource workOrderRemote,
  }) async {
    if (!commandType.endsWith('_work_order') &&
        !commandType.endsWith('_part') &&
        !commandType.contains('test_run')) {
      return;
    }
    try {
      final authoritative = await workOrderRemote.fetchWorkOrderById(
        aggregateId,
      );
      if (authoritative == null || !Hive.isBoxOpen(HiveBoxes.workOrdersBox)) {
        return;
      }
      final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
      final previous = box.get(authoritative.id);
      final localVoicePath = previous?.voiceNoteLocalPath;
      final uploadedVoicePath = localVoicePath == null
          ? null
          : '${authoritative.id}/voice-notes/'
                '${Uri.file(localVoicePath).pathSegments.last}';
      final voiceNoteConfirmed =
          uploadedVoicePath != null &&
          authoritative.voiceNoteUrl == uploadedVoicePath;
      await box.put(
        authoritative.id,
        !voiceNoteConfirmed && localVoicePath != null
            ? authoritative.copyWith(voiceNoteLocalPath: localVoicePath)
            : authoritative,
      );
      if (voiceNoteConfirmed) {
        final localFile = File(localVoicePath!);
        if (await localFile.exists()) await localFile.delete();
      }
      debugPrint(
        '🔄 Reconciled WorkOrder ${authoritative.id} to server version: ${authoritative.version}',
      );
    } catch (error) {
      debugPrint(
        '⚠️ OutboxSyncEngine failed to reconcile aggregate $aggregateId: $error',
      );
    }
  }
}
