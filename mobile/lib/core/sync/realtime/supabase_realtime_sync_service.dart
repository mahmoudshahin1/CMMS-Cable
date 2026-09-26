import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/hive_boxes.dart';
import '../outbox/outbox_local_data_source.dart';
import '../../../features/work_orders/domain/models/work_order_model.dart';
import '../../../features/work_orders/data/datasources/work_order_remote_mapper.dart';
import '../../../features/assets/domain/models/machine_model.dart';
import '../../../features/assets/data/datasources/machine_remote_mapper.dart';
import '../../../features/downtime/domain/models/downtime_log_model.dart';
import '../../../features/downtime/data/datasources/downtime_remote_mapper.dart';

import '../network/network_connectivity_checker.dart';
import '../delta/delta_sync_coordinator.dart';

/// Manages Supabase Realtime subscriptions and reconciles live events into Hive
/// with JWT refresh handling, conflict guards, and clean lifecycle management.
class SupabaseRealtimeSyncService {
  final SupabaseClient _client;
  final OutboxLocalDataSource _outboxLocal;
  final NetworkConnectivityChecker? _networkChecker;
  final DeltaSyncCoordinator? _deltaSyncCoordinator;

  RealtimeChannel? _channel;
  final _changeEventController = StreamController<String>.broadcast();
  StreamSubscription<bool>? _netSub;
  StreamSubscription<AuthState>? _authSub;

  SupabaseRealtimeSyncService({
    SupabaseClient? client,
    required OutboxLocalDataSource outboxLocal,
    NetworkConnectivityChecker? networkChecker,
    DeltaSyncCoordinator? deltaSyncCoordinator,
  })  : _client = client ?? Supabase.instance.client,
        _outboxLocal = outboxLocal,
        _networkChecker = networkChecker,
        _deltaSyncCoordinator = deltaSyncCoordinator {
    _initConnectivityCatchUp();
    _initAuthListener();
  }

  void _initConnectivityCatchUp() {
    _netSub = _networkChecker?.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('🌐 Network restored: re-subscribing realtime and triggering delta catch-up');
        reconnectWithAuth();
        _deltaSyncCoordinator?.syncDeltas();
      }
    });
  }

  void _initAuthListener() {
    try {
      _authSub = _client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.tokenRefreshed && data.session != null) {
          debugPrint('🔄 SupabaseRealtime: token refreshed, updating realtime auth');
          _client.realtime.setAuth(data.session!.accessToken);
        }
      });
    } catch (_) {
      // In mock/test environments Supabase auth might be offline
    }
  }

  Stream<String> get onRealtimeChange => _changeEventController.stream;

  void reconnectWithAuth() {
    unsubscribeAll();
    subscribe();
  }

  void subscribe() {
    if (_channel != null) return;

    final session = _client.auth.currentSession;
    if (session == null) {
      debugPrint('🛡️ SupabaseRealtimeSyncService: postpone subscribe (no active session)');
      return;
    }

    _channel = _client.channel('cmms-factory-realtime');

    // 1. Listen to work_orders
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'work_orders',
      callback: (payload) => _handleWorkOrderChange(payload),
    );

    // 2. Listen to machines
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'machines',
      callback: (payload) => _handleMachineChange(payload),
    );

    // 3. Listen to downtime_logs
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'downtime_logs',
      callback: (payload) => _handleDowntimeChange(payload),
    );

    _channel!.subscribe((status, [error]) {
      debugPrint('📡 SupabaseRealtime subscription status: $status (error: $error)');
    });
  }

  Future<void> _handleWorkOrderChange(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    final id = record['id'] as String?;
    if (id == null) return;

    final isDirtyLocal = await _outboxLocal.hasPendingForAggregate(id);
    if (isDirtyLocal) {
      debugPrint('🛡️ Realtime: ignoring server update for locally dirty WorkOrder $id');
      return;
    }

    try {
      final box = Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox);
      final existing = box.get(id);

      final updated = WorkOrderRemoteMapper.fromSupabaseRow(
        record,
        partsRows: existing?.spareParts.map((p) => p.toJson()).toList() ?? [],
        eventsRows: existing?.activityLogs.map((a) => a.toJson()).toList() ?? [],
      );

      await box.put(id, updated);
      _changeEventController.add('work_orders:$id');
    } catch (e) {
      debugPrint('⚠️ Error parsing realtime work order: $e');
    }
  }

  Future<void> _handleMachineChange(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    final id = record['id'] as String?;
    if (id == null) return;

    final isDirtyLocal = await _outboxLocal.hasPendingForAggregate(id);
    if (isDirtyLocal) {
      debugPrint('🛡️ Realtime: ignoring server update for locally dirty Machine $id');
      return;
    }

    try {
      final model = MachineRemoteMapper.fromSupabaseRow(record);
      final box = Hive.box<MachineModel>(HiveBoxes.machinesBox);
      await box.put(model.id, model);
      _changeEventController.add('machines:${model.id}');
    } catch (e) {
      debugPrint('⚠️ Error parsing realtime machine: $e');
    }
  }

  Future<void> _handleDowntimeChange(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    if (record.isEmpty) return;

    final id = record['id'] as String?;
    if (id == null) return;

    final isDirtyLocal = await _outboxLocal.hasPendingForAggregate(id);
    if (isDirtyLocal) {
      debugPrint('🛡️ Realtime: ignoring server update for locally dirty Downtime $id');
      return;
    }

    try {
      final model = DowntimeRemoteMapper.fromSupabaseRow(record);
      final box = Hive.box<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);
      await box.put(model.id, model);
      _changeEventController.add('downtime_logs:$id');
    } catch (e) {
      debugPrint('⚠️ Error parsing realtime downtime log: $e');
    }
  }

  void unsubscribeAll() {
    if (_channel != null) {
      try {
        _channel?.unsubscribe();
        _client.removeChannel(_channel!);
      } catch (e) {
        debugPrint('⚠️ Error removing realtime channel: $e');
      }
      _channel = null;
    }
  }

  void dispose() {
    _authSub?.cancel();
    _netSub?.cancel();
    unsubscribeAll();
    _changeEventController.close();
  }
}
