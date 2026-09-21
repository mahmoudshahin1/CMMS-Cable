import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/models/process_log_model.dart';
import 'machine_remote_data_source.dart';
import 'machine_remote_mapper.dart';

/// Supabase-backed implementation of [MachineRemoteDataSource].
class SupabaseMachineRemoteDataSource implements MachineRemoteDataSource {
  final SupabaseClient _client;

  SupabaseMachineRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<MachineModel>> fetchMachines() async {
    final rows = await _client
        .from('machines')
        .select()
        .order('code', ascending: true);

    return (rows as List)
        .map((r) => MachineRemoteMapper.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MachineModel?> fetchMachineById(String id) async {
    final row = await _client
        .from('machines')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return MachineRemoteMapper.fromSupabaseRow(row);
  }

  @override
  Future<List<MachineModel>> fetchModifiedAfter(DateTime cursor) async {
    final rows = await _client
        .from('machines')
        .select()
        .gt('updated_at', cursor.toUtc().toIso8601String())
        .order('updated_at', ascending: true);

    return (rows as List)
        .map((r) => MachineRemoteMapper.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> syncMachine(MachineModel machine) async {
    debugPrint('📡 SupabaseMachineRemoteDataSource: syncMachine ${machine.id}');
  }

  @override
  Future<void> syncProcessLog(ProcessLogModel log) async {
    debugPrint('📡 SupabaseMachineRemoteDataSource: syncProcessLog ${log.id}');
  }
}
