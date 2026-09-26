import '../models/downtime_log_model.dart';
import '../enums/downtime_category.dart';

abstract class DowntimeRepository {
  Future<List<DowntimeLogModel>> getAllDowntimeLogs();
  Future<List<DowntimeLogModel>> getActiveDowntimeLogs();
  Future<List<DowntimeLogModel>> getDowntimeLogsForMachine(String machineId);
  Future<DowntimeLogModel> createDowntimeLog(DowntimeLogModel log);
  Future<void> endDowntime(String logId, {String? comments});
  Future<void> updateCategory(String logId, DowntimeCategory newCategory);
  Future<void> attachWorkOrder(String logId, String workOrderId);
}
