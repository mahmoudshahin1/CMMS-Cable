import '../../../../core/sync/outbox/outbox_command.dart';

/// Maps a test-run outbox command to the named arguments accepted by
/// `rpc_confirm_test_run` in migration 20261106000012.
Map<String, dynamic> confirmTestRunRpcParams(OutboxCommand command) {
  final payload = command.payload;
  return {
    'p_command_id': command.commandId,
    'p_wo_id': command.aggregateId,
    'p_expected_version':
        command.expectedVersion ?? payload['expected_version'] ?? 1,
    'p_outcome': payload['outcome'] ?? 'fixed',
    'p_comments': payload['comments'],
    'p_confirmed_downtime_minutes': payload['confirmed_downtime_minutes'],
    'p_occurred_at': command.occurredAt.toUtc().toIso8601String(),
  };
}
