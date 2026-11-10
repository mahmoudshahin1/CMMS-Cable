import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../database/hive_boxes.dart';
import '../../storage/repair_audio_storage_path.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';

/// Replaces local aggregate state with server authority after a command resolves.
class OutboxAggregateReconciler {
  static Future<bool> reconcile({
    required String aggregateId,
    required String commandType,
    Map<String, dynamic>? commandPayload,
    required WorkOrderRemoteDataSource workOrderRemote,
  }) async {
    if (!commandType.endsWith('_work_order') &&
        !commandType.endsWith('_part') &&
        !commandType.contains('test_run')) {
      return true;
    }
    try {
      final queuedRepairPath =
          commandPayload?['repair_voice_local_path'] as String?;
      final queuedFaultPath =
          commandPayload?['voice_note_local_path'] as String?;
      final existingLocalVoicePath = Hive.isBoxOpen(HiveBoxes.workOrdersBox)
          ? Hive.box<WorkOrderModel>(
              HiveBoxes.workOrdersBox,
            ).get(aggregateId)?.voiceNoteLocalPath
          : null;
      final authoritative = await workOrderRemote.fetchWorkOrderById(
        aggregateId,
      );
      if (authoritative == null || !Hive.isBoxOpen(HiveBoxes.workOrdersBox)) {
        return false;
      }
      final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
      final previous = box.get(authoritative.id);
      final localVoicePath =
          previous?.voiceNoteLocalPath ??
          queuedFaultPath ??
          existingLocalVoicePath;
      final uploadedVoicePath = localVoicePath == null
          ? null
          : '${authoritative.id}/voice-notes/'
                '${Uri.file(localVoicePath).pathSegments.last}';
      final voiceNoteConfirmed =
          uploadedVoicePath != null &&
          authoritative.voiceNoteUrl == uploadedVoicePath;
      final localRepairPath = queuedRepairPath;
      final repairFileName = localRepairPath == null
          ? null
          : Uri.file(localRepairPath).pathSegments.last;
      final uploadedRepairPath = repairFileName == null
          ? null
          : RepairAudioStoragePath.forFile(
              workOrderId: authoritative.id,
              fileName: repairFileName,
            );
      final repairVoiceConfirmed =
          uploadedRepairPath != null &&
          authoritative.repairVoiceUrl == uploadedRepairPath;
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
      if (repairVoiceConfirmed) {
        final localFile = File(localRepairPath!);
        if (await localFile.exists()) await localFile.delete();
      }
      debugPrint(
        '🔄 Reconciled WorkOrder ${authoritative.id} to server version: ${authoritative.version}',
      );
      final needsVoiceConfirmation =
          localVoicePath != null || queuedFaultPath != null;
      final needsRepairVoiceConfirmation = localRepairPath != null;
      return (!needsVoiceConfirmation || voiceNoteConfirmed) &&
          (!needsRepairVoiceConfirmation || repairVoiceConfirmed);
    } catch (error) {
      debugPrint(
        '⚠️ OutboxSyncEngine failed to reconcile aggregate $aggregateId: $error',
      );
      return false;
    }
  }
}
