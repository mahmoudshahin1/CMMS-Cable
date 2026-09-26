import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_command.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_local_data_source.dart';

/// In-memory fake implementation of [OutboxLocalDataSource] for unit testing.
class FakeOutboxLocalDataSource implements OutboxLocalDataSource {
  final Map<String, OutboxCommand> _storage = {};

  @override
  Future<void> enqueue(OutboxCommand command) async {
    _storage[command.commandId] = command;
  }

  @override
  Future<List<OutboxCommand>> getPendingCommands() async {
    final list = _storage.values.where((c) {
      return c.status == OutboxCommandStatus.pending ||
          c.status == OutboxCommandStatus.inFlight;
    }).toList();
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  @override
  Future<List<OutboxCommand>> getCommandsForAggregate(
      String aggregateId) async {
    final list =
        _storage.values.where((c) => c.aggregateId == aggregateId).toList();
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  @override
  Future<bool> hasPendingForAggregate(String aggregateId) async {
    return _storage.values.any(
      (c) =>
          c.aggregateId == aggregateId &&
          (c.status == OutboxCommandStatus.pending ||
              c.status == OutboxCommandStatus.inFlight),
    );
  }

  @override
  Future<void> markInFlight(String commandId) async {
    final cmd = _storage[commandId];
    if (cmd != null) {
      _storage[commandId] =
          cmd.copyWith(status: OutboxCommandStatus.inFlight);
    }
  }

  @override
  Future<void> markCompleted(String commandId, {DateTime? processedAt}) async {
    final cmd = _storage[commandId];
    if (cmd != null) {
      _storage[commandId] = cmd.copyWith(
        status: OutboxCommandStatus.completed,
        processedAt: processedAt ?? DateTime.now(),
      );
    }
  }

  @override
  Future<void> markFailed(
    String commandId,
    String error, {
    bool isDeadLetter = false,
    DateTime? nextRetryAt,
  }) async {
    final cmd = _storage[commandId];
    if (cmd != null) {
      final nextStatus = isDeadLetter
          ? OutboxCommandStatus.deadLetter
          : OutboxCommandStatus.pending;
      _storage[commandId] = cmd.copyWith(
        status: nextStatus,
        attempts: cmd.attempts + 1,
        lastError: error,
        nextRetryAt: nextRetryAt,
      );
    }
  }

  @override
  Future<void> markTerminalFailure(
    String commandId,
    String error, {
    required OutboxCommandStatus status,
  }) async {
    final cmd = _storage[commandId];
    if (cmd != null) {
      _storage[commandId] = cmd.copyWith(
        status: status,
        attempts: cmd.attempts + 1,
        lastError: error,
        nextRetryAt: null,
        processedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteCommand(String commandId) async {
    _storage.remove(commandId);
  }

  @override
  Future<int> getPendingCount() async {
    return _storage.values
        .where((c) =>
            c.status == OutboxCommandStatus.pending ||
            c.status == OutboxCommandStatus.inFlight)
        .length;
  }

  @override
  Future<List<OutboxCommand>> getDeadLetterCommands() async {
    return _storage.values
        .where((c) => c.status == OutboxCommandStatus.deadLetter)
        .toList();
  }

  @override
  Future<void> clearCompleted() async {
    _storage.removeWhere((k, v) => v.status == OutboxCommandStatus.completed);
  }

  OutboxCommand? getCommand(String commandId) => _storage[commandId];
}
