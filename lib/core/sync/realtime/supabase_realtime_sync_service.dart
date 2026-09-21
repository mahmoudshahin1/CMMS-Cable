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

/// Manages Supabase Realtime subscriptions and reconciles live events into Hive.
class SupabaseRealtimeSyncService {
  final SupabaseClient _client;
  final OutboxLocalDataSource _outboxLocal;

  RealtimeChannel? _channel;
  final _changeEventController = StreamController<String>.broadcast();

  SupabaseRealtimeSyncService({
    SupabaseClient? client,
    required OutboxLocalDataSource outboxLocal,
  })  : _client = client ?? Supabase.instance.client,
        _outboxLocal = outboxLocal;

  Stream<String> get onRealtimeChange => _changeEventController.stream;

  void subscribe() {
    if (_channel != null) return;

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

  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  void dispose() {
    unsubscribe();
    _changeEventController.close();
  }
}
