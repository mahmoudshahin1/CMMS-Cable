import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/work_order_model.dart';
import '../../../../core/sync/outbox/outbox_command.dart';
import 'work_order_remote_data_source.dart';
import 'work_order_remote_mapper.dart';

/// Real Supabase-backed implementation of [WorkOrderRemoteDataSource].
class SupabaseWorkOrderRemoteDataSource implements WorkOrderRemoteDataSource {
  final SupabaseClient _client;

  SupabaseWorkOrderRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async {
    final rows = await _client
        .from('work_orders')
        .select('*, work_order_parts(*), work_order_events(*)')
        .order('created_at', ascending: false);

    return (rows as List).map((row) {
      final parts = (row['work_order_parts'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final events = (row['work_order_events'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      return WorkOrderRemoteMapper.fromSupabaseRow(
        row as Map<String, dynamic>,
        partsRows: parts,
        eventsRows: events,
      );
    }).toList();
  }

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async {
    final row = await _client
        .from('work_orders')
        .select('*, work_order_parts(*), work_order_events(*)')
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;

    final parts = (row['work_order_parts'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final events = (row['work_order_events'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    return WorkOrderRemoteMapper.fromSupabaseRow(
      row,
      partsRows: parts,
      eventsRows: events,
    );
  }

  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime cursor) async {
    final rows = await _client
        .from('work_orders')
        .select('*, work_order_parts(*), work_order_events(*)')
        .gt('updated_at', cursor.toUtc().toIso8601String())
        .order('updated_at', ascending: true);

    return (rows as List).map((row) {
      final parts = (row['work_order_parts'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final events = (row['work_order_events'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      return WorkOrderRemoteMapper.fromSupabaseRow(
        row as Map<String, dynamic>,
        partsRows: parts,
        eventsRows: events,
      );
    }).toList();
  }

  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {
    // Direct sync fallback if not dispatched via outbox
    debugPrint('📡 SupabaseWorkOrderRemoteDataSource: syncWorkOrder ${workOrder.id}');
  }

  @override
  Future<void> deleteRemoteWorkOrder(String id) async {
    // Direct deletions revoked at database layer; soft-close via RPC instead
    debugPrint('⚠️ Direct deletion of work order is revoked by server policy');
  }

  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async {
    final outboxCmd = command is OutboxCommand
        ? command
        : OutboxCommand.fromJson(command as Map<String, dynamic>);

    final rpcName = _resolveRpcName(outboxCmd.commandType);
    final params = _buildRpcParams(outboxCmd);

    debugPrint('📡 Supabase RPC Call: $rpcName [cmdId: ${outboxCmd.commandId}]');
    final response = await _client.rpc(rpcName, params: params);

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'result': response};
  }

  String _resolveRpcName(String commandType) {
    switch (commandType) {
      case 'create_work_order':
        return 'rpc_create_work_order';
      case 'assign_work_order':
        return 'rpc_assign_work_order';
      case 'start_work_order':
        return 'rpc_start_work_order';
      case 'add_work_order_part':
        return 'rpc_add_work_order_part';
      case 'complete_work_order':
        return 'rpc_complete_work_order';
      case 'confirm_test_run':
        return 'rpc_confirm_test_run';
      case 'close_work_order':
        return 'rpc_close_work_order';
      default:
        throw ArgumentError('Unknown work order command type: $commandType');
    }
  }

  Map<String, dynamic> _buildRpcParams(OutboxCommand cmd) {
    final p = cmd.payload;
    final occurredIso = cmd.occurredAt.toUtc().toIso8601String();

    switch (cmd.commandType) {
      case 'create_work_order':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_title': p['title'],
          'p_description': p['description'] ?? '',
          'p_machine_id': p['machine_id'],
          'p_type': p['type'] ?? 'breakdown',
          'p_priority': p['priority'] ?? 'medium',
          'p_client_occurred_at': occurredIso,
        };
      case 'assign_work_order':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_expected_version': cmd.expectedVersion ?? p['expected_version'] ?? 1,
          'p_technician_id': p['technician_id'],
          'p_client_occurred_at': occurredIso,
        };
      case 'start_work_order':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_expected_version': cmd.expectedVersion ?? p['expected_version'] ?? 1,
          'p_client_occurred_at': occurredIso,
        };
      case 'add_work_order_part':
        return {
          'p_command_id': cmd.commandId,
          'p_part_id': p['part_id'],
          'p_work_order_id': cmd.aggregateId,
          'p_part_code': p['part_code'] ?? '',
          'p_part_name': p['part_name'],
          'p_quantity': p['quantity'],
          'p_unit_cost': p['unit_cost'] ?? 0.0,
          'p_client_occurred_at': occurredIso,
        };
      case 'complete_work_order':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_expected_version': cmd.expectedVersion ?? p['expected_version'] ?? 1,
          'p_root_cause': p['root_cause'] ?? '',
          'p_actions_taken': p['actions_taken'] ?? '',
          'p_client_occurred_at': occurredIso,
        };
      case 'confirm_test_run':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_expected_version': cmd.expectedVersion ?? p['expected_version'] ?? 1,
          'p_client_occurred_at': occurredIso,
        };
      case 'close_work_order':
        return {
          'p_command_id': cmd.commandId,
          'p_work_order_id': cmd.aggregateId,
          'p_expected_version': cmd.expectedVersion ?? p['expected_version'] ?? 1,
          'p_client_occurred_at': occurredIso,
        };
      default:
        return {'p_command_id': cmd.commandId, ...p};
    }
  }
}
