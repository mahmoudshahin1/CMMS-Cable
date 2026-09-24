import 'package:flutter/foundation.dart';

enum SyncState {
  idle,
  syncing,
  success,
  offline,
  error,
}

@immutable
class SyncStatus {
  final SyncState state;
  final String? message;
  final int pendingOutboxCount;
  final DateTime? lastSyncedAt;
  final bool isInitialSync;

  const SyncStatus({
    this.state = SyncState.idle,
    this.message,
    this.pendingOutboxCount = 0,
    this.lastSyncedAt,
    this.isInitialSync = false,
  });

  SyncStatus copyWith({
    SyncState? state,
    String? message,
    int? pendingOutboxCount,
    DateTime? lastSyncedAt,
    bool? isInitialSync,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isInitialSync: isInitialSync ?? this.isInitialSync,
    );
  }

  @override
  String toString() =>
      'SyncStatus(state: $state, pending: $pendingOutboxCount, last: $lastSyncedAt)';
}
