import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/storage/attachment_service.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/work_order_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/models/repair_step_model.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_status.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/work_order_type.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/domain/enums/priority.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_outbox_factory.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/voice_note_recorder_widget.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/presentation/widgets/voice_note_player_view.dart';

void main() {
  group('AttachmentService Voice Note Validation & Storage Tests', () {
    late AttachmentService attachmentService;

    setUp(() {
      attachmentService = AttachmentService();
    });

    test('accepts valid voice audio extensions within 10MB limit', () {
      final validFiles = [
        'operator_fault.m4a',
        'tech_remarks.mp3',
        'sound_recording.wav',
        'voice_note.aac',
        'audio_clip.ogg',
        'UPPERCASE_VOICE.M4A',
      ];

      for (final file in validFiles) {
        expect(
          () => attachmentService.validateVoiceNote(
            sizeBytes: 2 * 1024 * 1024,
            fileName: file,
          ),
          returnsNormally,
          reason: 'Failed on valid voice file: $file',
        );
      }
    });

    test('rejects empty or zero-byte audio file', () {
      expect(
        () => attachmentService.validateVoiceNote(
          sizeBytes: 0,
          fileName: 'empty_record.m4a',
        ),
        throwsA(
          isA<AttachmentValidationException>().having(
            (e) => e.message,
            'message',
            contains('cannot be empty'),
          ),
        ),
      );
    });

    test('rejects non-audio file extensions for voice note', () {
      final invalidFiles = [
        'payload.exe',
        'photo.jpg',
        'script.sh',
        'document.pdf',
      ];

      for (final file in invalidFiles) {
        expect(
          () => attachmentService.validateVoiceNote(
            sizeBytes: 1024,
            fileName: file,
          ),
          throwsA(
            isA<AttachmentValidationException>().having(
              (e) => e.message,
              'message',
              contains('Disallowed voice format'),
            ),
          ),
          reason: 'Failed to reject non-audio format: $file',
        );
      }
    });
  });

  group('WorkOrder Outbox Factory RPC Keys Tests', () {
    test('create command produces p_voice_note_url parameter in payload', () {
      final wo = WorkOrderModel(
        id: 'wo-create-1',
        title: 'Breakdown title',
        description: 'Details',
        machineId: 'DW01',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.open,
        priority: Priority.high,
        createdAt: DateTime.now(),
        voiceNoteUrl: 'voice-notes/wo-create-1/17300000.m4a',
      );

      final cmd = WorkOrderOutboxFactory.create(wo);
      expect(
        cmd.payload['p_voice_note_url'],
        'voice-notes/wo-create-1/17300000.m4a',
      );
      expect(
        cmd.payload['voice_note_url'],
        'voice-notes/wo-create-1/17300000.m4a',
      );
    });

    test('create command keeps local recording path for offline upload', () {
      final wo = WorkOrderModel(
        id: 'wo-offline-audio',
        title: 'Breakdown title',
        description: 'Details',
        machineId: 'DW01',
        type: WorkOrderType.breakdown,
        status: WorkOrderStatus.open,
        priority: Priority.high,
        createdAt: DateTime.now(),
        voiceNoteLocalPath: r'C:\app\voice_note.m4a',
      );

      final command = WorkOrderOutboxFactory.create(wo);
      expect(
        command.payload['voice_note_local_path'],
        r'C:\app\voice_note.m4a',
      );
      expect(command.payload['voice_note_command_id'], isA<String>());
      expect(command.payload, isNot(contains('p_voice_note_url')));

      final restored = WorkOrderModel.fromJson(wo.toJson());
      expect(restored.voiceNoteLocalPath, wo.voiceNoteLocalPath);
    });

    test(
      'complete command produces p_repair_steps and p_repair_voice_url in payload',
      () {
        final wo = WorkOrderModel(
          id: 'wo-comp-1',
          title: 'Repair done',
          description: 'Details',
          machineId: 'DW01',
          type: WorkOrderType.breakdown,
          status: WorkOrderStatus.inProgress,
          priority: Priority.high,
          createdAt: DateTime.now(),
        );

        final steps = [
          const RepairStepModel(id: 's1', description: 'Replaced bearing'),
        ];

        final cmd = WorkOrderOutboxFactory.complete(
          wo,
          rootCause: 'Bearing wear',
          actionsTaken: 'Replaced',
          repairSteps: steps,
          repairVoiceUrl: 'voice-notes/wo-comp-1/17300099.m4a',
        );

        expect(
          cmd.payload['p_repair_voice_url'],
          'voice-notes/wo-comp-1/17300099.m4a',
        );
        expect(cmd.payload['p_repair_steps'], isNotEmpty);
        expect(cmd.payload['repair_steps'], isNotEmpty);
      },
    );
  });

  group('Voice Note UI Widgets Tests', () {
    testWidgets('renders player view when audio URL is present', (
      tester,
    ) async {
      String? changedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceNoteRecorderWidget(
              label: 'Fault Voice Note',
              initialAudioUrl: 'voice-notes/wo-1/17300000.m4a',
              isEditable: true,
              onAudioUrlChanged: (url) => changedUrl = url,
            ),
          ),
        ),
      );

      expect(find.text('FAULT VOICE NOTE'), findsOneWidget);
      expect(find.byType(VoiceNotePlayerView), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

      final deleteBtn = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteBtn);
      await tester.pump();

      expect(changedUrl, isNull);
    });
  });
}
