import 'package:hive/hive.dart';
import '../../domain/repositories/downtime_repository.dart';
import '../../domain/models/downtime_log_model.dart';
import '../../domain/enums/downtime_category.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/chronology/event_chronology.dart';

class HiveDowntimeRepository implements DowntimeRepository {
  Box<DowntimeLogModel> get _box =>
      Hive.box<DowntimeLogModel>(HiveBoxes.downtimeLogsBox);

  @override
  Future<List<DowntimeLogModel>> getAllDowntimeLogs() async {
    return _box.values.toList();
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
  Future<DowntimeLogModel> createDowntimeLog(DowntimeLogModel log) async {
    final startChrono = log.startChronology ?? EventChronology.fromDateTime(log.startTime);
    final withChrono = log.copyWith(
      startTime: startChrono.recordedAtUtc,
      startChronology: startChrono,
    );
    await _box.put(withChrono.id, withChrono);
    return withChrono;
  }

  @override
  Future<void> endDowntime(String logId, {String? comments}) async {
    final log = _box.get(logId);
    if (log != null) {
      final endChrono = EventChronology.now();
      final updated = log.copyWith(
        endTime: endChrono.recordedAtUtc,
        endChronology: endChrono,
        comments: comments ?? log.comments,
      );
      await _box.put(logId, updated);
    }
  }

  @override
  Future<void> updateCategory(
      String logId, DowntimeCategory newCategory) async {
    final log = _box.get(logId);
    if (log != null) {
      final updated = log.copyWith(category: newCategory);
      await _box.put(logId, updated);
    }
  }

  @override
  Future<void> attachWorkOrder(String logId, String workOrderId) async {
    final log = _box.get(logId);
    if (log != null) {
      final updated = log.copyWith(workOrderId: workOrderId);
      await _box.put(logId, updated);
    }
  }
}
