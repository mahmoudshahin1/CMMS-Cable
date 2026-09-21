import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Execution lifecycle states of an [OutboxCommand].
enum OutboxCommandStatus {
  pending,
  inFlight,
  completed,
  failed,
  deadLetter,
}

/// Durable command envelope persisted in Hive for offline-first transactional mutations.
class OutboxCommand extends Equatable {
  final String commandId;
  final String commandType;
  final String aggregateId;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;
  final OutboxCommandStatus status;
  final int attempts;
  final String? lastError;
  final int? expectedVersion;
  final DateTime? processedAt;

  const OutboxCommand({
    required this.commandId,
    required this.commandType,
    required this.aggregateId,
    required this.payload,
    required this.occurredAt,
    this.status = OutboxCommandStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.expectedVersion,
    this.processedAt,
  });

  OutboxCommand copyWith({
    String? commandId,
    String? commandType,
    String? aggregateId,
    Map<String, dynamic>? payload,
    DateTime? occurredAt,
    OutboxCommandStatus? status,
    int? attempts,
    String? lastError,
    int? expectedVersion,
    DateTime? processedAt,
  }) {
    return OutboxCommand(
      commandId: commandId ?? this.commandId,
      commandType: commandType ?? this.commandType,
      aggregateId: aggregateId ?? this.aggregateId,
      payload: payload ?? this.payload,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commandId': commandId,
      'commandType': commandType,
      'aggregateId': aggregateId,
      'payload': jsonEncode(payload),
      'occurredAt': occurredAt.toIso8601String(),
      'status': status.name,
      'attempts': attempts,
      'lastError': lastError,
      'expectedVersion': expectedVersion,
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory OutboxCommand.fromJson(Map<String, dynamic> json) {
    dynamic rawPayload = json['payload'];
    Map<String, dynamic> parsedPayload;
    if (rawPayload is String) {
      try {
        parsedPayload = jsonDecode(rawPayload) as Map<String, dynamic>;
      } catch (_) {
        parsedPayload = {};
      }
    } else if (rawPayload is Map) {
      parsedPayload = Map<String, dynamic>.from(rawPayload);
    } else {
      parsedPayload = {};
    }

    return OutboxCommand(
      commandId: json['commandId'] as String,
      commandType: json['commandType'] as String,
      aggregateId: json['aggregateId'] as String,
      payload: parsedPayload,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      status: OutboxCommandStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OutboxCommandStatus.pending,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
      expectedVersion: (json['expectedVersion'] as num?)?.toInt(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        commandId,
        commandType,
        aggregateId,
        payload,
        occurredAt,
        status,
        attempts,
        lastError,
        expectedVersion,
        processedAt,
      ];
}
