import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sync_status.dart';
import '../network/network_connectivity_checker.dart';
import '../outbox/outbox_sync_engine.dart';
import '../delta/delta_sync_coordinator.dart';
import '../realtime/supabase_realtime_sync_service.dart';
import '../../../features/auth/domain/models/user_model.dart';

/// Central coordinator managing both Push (Outbox mutations) and Pull
/// (Delta/Initial sync & Realtime subscriptions) with shared connectivity,
/// unified heartbeat, and strict auth-gating.
class SyncManager {
  final OutboxSyncEngine _outboxEngine;
  final DeltaSyncCoordinator _deltaCoordinator;
  final SupabaseRealtimeSyncService _realtimeService;
  final NetworkConnectivityChecker? _networkChecker;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<SyncStatus>? _deltaSub;
  StreamSubscription<int>? _outboxCountSub;
  StreamSubscription<bool>? _networkSub;
  Timer? _heartbeatTimer;

  bool _isCoordinating = false;
  UserModel? _currentUser;

  SyncManager({
    required OutboxSyncEngine outboxEngine,
    required DeltaSyncCoordinator deltaCoordinator,
    required SupabaseRealtimeSyncService realtimeService,
    NetworkConnectivityChecker? networkChecker,
  })  : _outboxEngine = outboxEngine,
        _deltaCoordinator = deltaCoordinator,
        _realtimeService = realtimeService,
        _networkChecker = networkChecker {
    _initForwarding();
    _initSharedConnectivity();
  }

  Stream<SyncStatus> get statusStream => _syncStatusController.stream;
  SyncStatus get currentStatus => _deltaCoordinator.currentStatus;
  UserModel? get currentUser => _currentUser;

  void _initForwarding() {
    _deltaSub = _deltaCoordinator.statusStream.listen((status) {
      _syncStatusController.add(status);
    });

    _outboxCountSub = _outboxEngine.pendingCountStream.listen((count) {
      _syncStatusController.add(
        _deltaCoordinator.currentStatus.copyWith(pendingOutboxCount: count),
      );
    });
  }

  void _initSharedConnectivity() {
    _networkSub = _networkChecker?.onConnectivityChanged.listen((isOnline) {
      if (isOnline && _currentUser != null) {
        debugPrint('🌐 SyncManager: network restored, running unified Push-then-Pull cycle');
        unawaited(syncAll());
      }
    });
  }

  /// Called after successful login or session restoration.
  Future<void> onUserAuthenticated(UserModel user, {bool forceInitialSync = false}) async {
    _currentUser = user;
    debugPrint('🔐 SyncManager: onUserAuthenticated for ${user.email} (${user.role})');

    // 1. Reconnect realtime with authenticated token
    _realtimeService.reconnectWithAuth();

    // 2. Start shared periodic heartbeat (every 15s)
    _startSharedHeartbeat();

    // 3. Run complete initial Push-then-Pull cycle
    await syncAll(isInitial: true, forceFullPull: forceInitialSync);
  }

  /// Called on user logout.
  void onUserLoggedOut() {
    debugPrint('🚪 SyncManager: onUserLoggedOut, tearing down realtime and heartbeat');
    _currentUser = null;
    _stopSharedHeartbeat();
    _realtimeService.unsubscribeAll();
    _syncStatusController.add(const SyncStatus(state: SyncState.idle));
  }

  /// Unified synchronization cycle:
  /// STEP 1: Flush Outbox (PUSH)
  /// STEP 2: Pull Deltas / Full Data (PULL)
  /// Order is strictly maintained to prevent server data from overwriting
  /// pending local changes before they are dispatched.
  Future<void> syncAll({
    bool isInitial = false,
    bool forceFullPull = false,
  }) async {
    if (_isCoordinating) {
      debugPrint('⏳ SyncManager: coordination already in progress, skipping overlapping trigger');
      return;
    }

    // Verify session
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('🛡️ SyncManager: no active Supabase session, skipping syncAll');
        return;
      }
    } catch (_) {
      // Mock / offline testing
    }

    _isCoordinating = true;
    try {
      // Check network
      if (_networkChecker != null) {
        final online = await _networkChecker.isOnline;
        if (!online) {
          _syncStatusController.add(
            _deltaCoordinator.currentStatus.copyWith(state: SyncState.offline),
          );
          return;
        }
      }

      // Step 1: PUSH pending local commands
      debugPrint('⬆️ SyncManager [1/2]: Flushing local outbox commands');
      await _outboxEngine.syncNow();

      // Step 2: PULL latest server updates
      debugPrint('⬇️ SyncManager [2/2]: Pulling latest server state (initial: $isInitial, forceFull: $forceFullPull)');
      if (isInitial || forceFullPull) {
        await _deltaCoordinator.initialSync(forceFull: forceFullPull);
      } else {
        await _deltaCoordinator.syncDeltas();
      }
    } catch (e) {
      debugPrint('❌ SyncManager error in syncAll: $e');
    } finally {
      _isCoordinating = false;
    }
  }

  void _startSharedHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isCoordinating && _currentUser != null) {
        syncAll();
      }
    });
  }

  void _stopSharedHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void dispose() {
    _stopSharedHeartbeat();
    _deltaSub?.cancel();
    _outboxCountSub?.cancel();
    _networkSub?.cancel();
    _syncStatusController.close();
  }
}
