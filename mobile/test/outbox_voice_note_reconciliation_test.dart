import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/chronology_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/spare_part_adapter.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/work_order_activity_log_adapter.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/work_order_model_adapter.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/sync/outbox/outbox_aggregate_reconciler.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_data_source.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';

class _WorkOrderRemote implements WorkOrderRemoteDataSource {
  final WorkOrderModel? authoritative;
  _WorkOrderRemote(this.authoritative);

  @override
  Future<WorkOrderModel?> fetchWorkOrderById(String id) async => authoritative;
  @override
  Future<List<WorkOrderModel>> fetchWorkOrders() async => [];
  @override
  Future<List<WorkOrderModel>> fetchModifiedAfter(DateTime cursor) async => [];
  @override
  Future<Map<String, dynamic>> executeCommand(dynamic command) async => {};
  @override
  Future<void> syncWorkOrder(WorkOrderModel workOrder) async {}
  @override
  Future<void> deleteRemoteWorkOrder(String id) async {}
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cmms_voice_reconcile');
    Hive.init(tempDir.path);
    Hive.registerAdapter(WorkOrderTypeAdapter());
    Hive.registerAdapter(WorkOrderStatusAdapter());
    Hive.registerAdapter(PriorityAdapter());
    Hive.registerAdapter(PlantShiftAdapter());
    Hive.registerAdapter(EventChronologyAdapter());
    Hive.registerAdapter(SparePartModelAdapter());
    Hive.registerAdapter(WorkOrderActivityLogAdapter());
    Hive.registerAdapter(WorkOrderModelAdapter());
    await Hive.openBox<WorkOrderModel>(HiveBoxes.workOrdersBox);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() => Hive.box<WorkOrderModel>(HiveBoxes.workOrdersBox).clear());

  WorkOrderModel workOrder(
    String id, {
    String? localPath,
    String? remotePath,
  }) => WorkOrderModel(
    id: id,
    title: 'Breakdown',
    description: 'Details',
    machineId: 'DW01',
    type: WorkOrderType.breakdown,
    status: WorkOrderStatus.open,
    priority: Priority.high,
    createdAt: DateTime.now(),
    voiceNoteLocalPath: localPath,
    voiceNoteUrl: remotePath,
  );

  test(
    'keeps a local recording unless server confirms the matching path',
    () async {
      const woId = 'wo-voice-local';
      final file = File('${tempDir.path}/voice_note.m4a');
      await file.writeAsBytes([1, 2, 3]);
      await Hive.box<WorkOrderModel>(
        HiveBoxes.workOrdersBox,
      ).put(woId, workOrder(woId, localPath: file.path));

      await OutboxAggregateReconciler.reconcile(
        aggregateId: woId,
        commandType: 'create_work_order',
        workOrderRemote: _WorkOrderRemote(workOrder(woId)),
      );

      final saved = Hive.box<WorkOrderModel>(
        HiveBoxes.workOrdersBox,
      ).get(woId)!;
      expect(saved.voiceNoteLocalPath, file.path);
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'deletes the local recording after the remote path is confirmed',
    () async {
      const woId = 'wo-voice-uploaded';
      final file = File('${tempDir.path}/voice_note.m4a');
      await file.writeAsBytes([1, 2, 3]);
      await Hive.box<WorkOrderModel>(
        HiveBoxes.workOrdersBox,
      ).put(woId, workOrder(woId, localPath: file.path));

      await OutboxAggregateReconciler.reconcile(
        aggregateId: woId,
        commandType: 'create_work_order',
        workOrderRemote: _WorkOrderRemote(
          workOrder(woId, remotePath: '$woId/voice-notes/voice_note.m4a'),
        ),
      );

      final saved = Hive.box<WorkOrderModel>(
        HiveBoxes.workOrdersBox,
      ).get(woId)!;
      expect(saved.voiceNoteUrl, '$woId/voice-notes/voice_note.m4a');
      expect(saved.voiceNoteLocalPath, isNull);
      expect(await file.exists(), isFalse);
    },
  );
}
