import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../../../core/sync/outbox/outbox_command.dart';
import 'downtime_remote_data_source.dart';
import 'downtime_remote_mapper.dart';

/// Supabase-backed implementation of [DowntimeRemoteDataSource].
class SupabaseDowntimeRemoteDataSource implements DowntimeRemoteDataSource {
  final SupabaseClient _client;

  SupabaseDowntimeRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<DowntimeLogModel>> fetchDowntimeLogs() async {
    final rows = await _client
        .from('downtime_logs')
        .select()
        .order('started_at', ascending: false);

    return (rows as List)
        .map((r) => DowntimeRemoteMapper.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DowntimeLogModel>> fetchActiveDowntimeLogs() async {
    final rows = await _client
        .from('downtime_logs')
        .select()
        .isFilter('ended_at', null)
        .order('started_at', ascending: false);

    return (rows as List)
        .map((r) => DowntimeRemoteMapper.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DowntimeLogModel>> fetchModifiedAfter(DateTime cursor) async {
    final rows = await _client
        .from('downtime_logs')
        .select()
        .gt('updated_at', cursor.toUtc().toIso8601String())
        .order('updated_at', ascending: true);

    return (rows as List)
        .map((r) => DowntimeRemoteMapper.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> syncDowntimeLog(DowntimeLogModel log) async {
    debugPrint('📡 SupabaseDowntimeRemoteDataSource: syncDowntimeLog ${log.id}');
  }

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final outboxCmd = command is OutboxCommand
        ? command
        : OutboxCommand.fromJson(command as Map<String, dynamic>);

    final isCreate = outboxCmd.commandType == 'create_downtime_log';
    final rpcName = isCreate ? 'rpc_create_downtime_log' : 'rpc_close_downtime_log';
    final p = outboxCmd.payload;

    final Map<String, dynamic> params;
    if (isCreate) {
      params = {
        'p_id': outboxCmd.aggregateId,
        'p_machine_id': p['machine_id'],
        'p_category': p['category'] ?? 'other',
        'p_reason': p['reason'] ?? '',
        'p_is_maintenance_requested': p['is_maintenance_requested'] ?? false,
        'p_work_order_id': p['work_order_id'],
        'p_comments': p['comments'],
        'p_start_chronology': p['start_chronology'],
        'p_shift_minutes': p['shift_minutes'] ?? {},
      };
    } else {
      params = {
        'p_id': outboxCmd.aggregateId,
        'p_end_chronology': p['end_chronology'],
        'p_shift_minutes': p['shift_minutes'] ?? {},
      };
    }

    debugPrint('📡 Supabase Downtime RPC: $rpcName [id: ${outboxCmd.aggregateId}]');
    final response = await _client.rpc(rpcName, params: params);

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'result': response};
  }
}
