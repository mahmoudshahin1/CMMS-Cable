import '../../../features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'outbox_aggregate_reconciler.dart';
import 'outbox_command.dart';

/// Keeps command dispatch and its server-authority reconciliation together.
class OutboxCommandReconciliation {
  static Future<bool> afterSuccess({
    required OutboxCommand command,
    required WorkOrderRemoteDataSource workOrderRemote,
  }) async {
    if (command.commandType != 'create_work_order' &&
        command.commandType != 'complete_work_order') {
      return true;
    }

    final reconciled = await OutboxAggregateReconciler.reconcile(
      aggregateId: command.aggregateId,
      commandType: command.commandType,
      commandPayload: command.payload,
      workOrderRemote: workOrderRemote,
    );
    final audioPath =
        command.payload['repair_voice_local_path'] ??
        command.payload['voice_note_local_path'];
    return reconciled || audioPath is! String || audioPath.isEmpty;
  }

  static Future<void> afterTerminalFailure({
    required OutboxCommand command,
    required WorkOrderRemoteDataSource workOrderRemote,
  }) async {
    await OutboxAggregateReconciler.reconcile(
      aggregateId: command.aggregateId,
      commandType: command.commandType,
      commandPayload: command.payload,
      workOrderRemote: workOrderRemote,
    );
  }
}
