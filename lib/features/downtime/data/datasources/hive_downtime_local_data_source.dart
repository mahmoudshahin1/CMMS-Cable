import 'package:hive/hive.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../domain/models/downtime_log_model.dart';
import 'downtime_local_data_source.dart';

/// Hive implementation of [DowntimeLocalDataSource].
///
/// Encapsulates direct Hive box operations for downtime logs.
class HiveDowntimeLocalDataSource implements DowntimeLocalDataSource {
  Box<DowntimeLogModel> get _box =>
      Hive.box<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);

  @override
  Future<List<DowntimeLogModel>> getAllDowntimeLogs() async {
    return _box.values.toList();
  }

  @override
  Future<DowntimeLogModel?> getDowntimeLogById(String id) async {
    return _box.get(id);
  }

  @override
  Future<List<DowntimeLogModel>> getActiveDowntimeLogs() async {
    return _box.values.where((log) => log.isActive).toList();
  }

  @override
  Future<List<DowntimeLogModel>> getDowntimeLogsForMachine(
      String machineId) async {
    return _box.values.where((log) => log.machineId == machineId).toList();
  }

  @override
  Future<void> cacheDowntimeLog(DowntimeLogModel downtimeLog) async {
    await _box.put(downtimeLog.id, downtimeLog);
  }

  @override
  Future<void> cacheDowntimeLogs(List<DowntimeLogModel> logs) async {
    final map = {for (final log in logs) log.id: log};
    await _box.putAll(map);
  }

  @override
  Future<void> updateDowntimeLog(DowntimeLogModel downtimeLog) async {
    await _box.put(downtimeLog.id, downtimeLog);
  }

  @override
  Future<void> deleteDowntimeLog(String id) async {
    await _box.delete(id);
  }
}
