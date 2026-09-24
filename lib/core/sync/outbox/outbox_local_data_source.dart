import 'package:hive/hive.dart';
import '../../database/hive_boxes.dart';
import 'outbox_command.dart';

/// Contract for local durable outbox storage operations.
abstract class OutboxLocalDataSource {
  Future<void> enqueue(OutboxCommand command);
  Future<List<OutboxCommand>> getPendingCommands();
  Future<List<OutboxCommand>> getCommandsForAggregate(String aggregateId);
  Future<bool> hasPendingForAggregate(String aggregateId);
  Future<void> markInFlight(String commandId);
  Future<void> markCompleted(String commandId, {DateTime? processedAt});
  Future<void> markFailed(
    String commandId,
    String error, {
    bool isDeadLetter = false,
    DateTime? nextRetryAt,
  });
  Future<void> markTerminalFailure(
    String commandId,
    String error, {
    required OutboxCommandStatus status,
  });
  Future<void> deleteCommand(String commandId);
  Future<int> getPendingCount();
  Future<List<OutboxCommand>> getDeadLetterCommands();
  Future<void> clearCompleted();
}

/// Hive-backed implementation of [OutboxLocalDataSource].
class HiveOutboxLocalDataSource implements OutboxLocalDataSource {
  final Box<OutboxCommand>? _injectedBox;

  HiveOutboxLocalDataSource({Box<OutboxCommand>? box})
      : _injectedBox = box;

  Box<OutboxCommand> get _box =>
      _injectedBox ?? Hive.box<OutboxCommand>(HiveBoxes.outboxCommandsBox);

  @override
  Future<void> enqueue(OutboxCommand command) async {
    await _box.put(command.commandId, command);
  }

  @override
  Future<List<OutboxCommand>> getPendingCommands() async {
    final now = DateTime.now();
    final list = _box.values.where((c) {
      if (c.status != OutboxCommandStatus.pending &&
          c.status != OutboxCommandStatus.inFlight) {
        return false;
      }
      if (c.nextRetryAt != null && c.nextRetryAt!.isAfter(now)) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  @override
  Future<List<OutboxCommand>> getCommandsForAggregate(
      String aggregateId) async {
    final list = _box.values
        .where((c) => c.aggregateId == aggregateId)
        .toList();
    list.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return list;
  }

  @override
  Future<bool> hasPendingForAggregate(String aggregateId) async {
    return _box.values.any(
      (c) =>
          c.aggregateId == aggregateId &&
          (c.status == OutboxCommandStatus.pending ||
              c.status == OutboxCommandStatus.inFlight),
    );
  }

  @override
  Future<void> markInFlight(String commandId) async {
    final cmd = _box.get(commandId);
    if (cmd != null) {
      await _box.put(
        commandId,
        cmd.copyWith(status: OutboxCommandStatus.inFlight),
      );
    }
  }

  @override
  Future<void> markCompleted(String commandId, {DateTime? processedAt}) async {
    final cmd = _box.get(commandId);
    if (cmd != null) {
      await _box.put(
        commandId,
        cmd.copyWith(
          status: OutboxCommandStatus.completed,
          processedAt: processedAt ?? DateTime.now(),
        ),
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
    final cmd = _box.get(commandId);
    if (cmd != null) {
      final nextStatus = isDeadLetter
          ? OutboxCommandStatus.deadLetter
          : OutboxCommandStatus.pending;
      await _box.put(
        commandId,
        cmd.copyWith(
          status: nextStatus,
          attempts: cmd.attempts + 1,
          lastError: error,
          nextRetryAt: nextRetryAt,
        ),
      );
    }
  }

  @override
  Future<void> markTerminalFailure(
    String commandId,
    String error, {
    required OutboxCommandStatus status,
  }) async {
    final cmd = _box.get(commandId);
    if (cmd != null) {
      await _box.put(
        commandId,
        cmd.copyWith(
          status: status,
          attempts: cmd.attempts + 1,
          lastError: error,
          nextRetryAt: null,
          processedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> deleteCommand(String commandId) async {
    await _box.delete(commandId);
  }

  @override
  Future<int> getPendingCount() async {
    return _box.values
        .where((c) =>
            c.status == OutboxCommandStatus.pending ||
            c.status == OutboxCommandStatus.inFlight)
        .length;
  }

  @override
  Future<List<OutboxCommand>> getDeadLetterCommands() async {
    return _box.values
        .where((c) => c.status == OutboxCommandStatus.deadLetter)
        .toList();
  }

  @override
  Future<void> clearCompleted() async {
    final completedKeys = _box.values
        .where((c) => c.status == OutboxCommandStatus.completed)
        .map((c) => c.commandId)
        .toList();
    await _box.deleteAll(completedKeys);
  }
}
