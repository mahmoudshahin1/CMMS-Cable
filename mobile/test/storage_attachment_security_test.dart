import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/storage/attachment_service.dart';

void main() {
  group('AttachmentService Security & Validation Unit Tests', () {
    late AttachmentService attachmentService;

    setUp(() {
      // In standalone unit testing without network, test validation logic directly.
      attachmentService = AttachmentService();
    });

    test('accepts valid image extensions within 10MB limit', () {
      final validFiles = [
        'fault_photo.jpg',
        'damage.jpeg',
        'extrusion_crack.png',
        'bearing_wear.webp',
        'UPPERCASE_TEST.PNG',
        'mixed_case.JpEg',
      ];

      for (final fileName in validFiles) {
        expect(
          () => attachmentService.validateAttachment(
            sizeBytes: 5 * 1024 * 1024, // 5MB
            fileName: fileName,
          ),
          returnsNormally,
          reason: 'Failed on valid file: $fileName',
        );
      }
    });

    test('rejects empty file (0 bytes)', () {
      expect(
        () => attachmentService.validateAttachment(
          sizeBytes: 0,
          fileName: 'photo.jpg',
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

    test('rejects negative size bytes', () {
      expect(
        () => attachmentService.validateAttachment(
          sizeBytes: -10,
          fileName: 'photo.jpg',
        ),
        throwsA(isA<AttachmentValidationException>()),
      );
    });

    test('rejects files exceeding 10MB limit', () {
      const overLimitBytes = (10 * 1024 * 1024) + 1; // 10MB + 1 byte
      expect(
        () => attachmentService.validateAttachment(
          sizeBytes: overLimitBytes,
          fileName: 'high_res_photo.jpg',
        ),
        throwsA(
          isA<AttachmentValidationException>().having(
            (e) => e.message,
            'message',
            contains('exceeds maximum 10MB limit'),
          ),
        ),
      );
    });

    test('strictly rejects dangerous non-image file extensions', () {
      final disallowedFiles = [
        'payload.exe',
        'script.sh',
        'exploit.php',
        'document.pdf',
        'data.json',
        'archive.zip',
        'app.apk',
        'vector.svg', // SVG can contain embedded scripts / XSS
        'no_extension',
      ];

      for (final fileName in disallowedFiles) {
        expect(
          () => attachmentService.validateAttachment(
            sizeBytes: 1024,
            fileName: fileName,
          ),
          throwsA(
            isA<AttachmentValidationException>().having(
              (e) => e.message,
              'message',
              contains('Disallowed file extension'),
            ),
          ),
          reason: 'Failed to reject disallowed file: $fileName',
        );
      }
    });

    test('uploadAttachment rejects empty workOrderId', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);

      await expectLater(
        attachmentService.uploadAttachment(
          workOrderId: '',
          bytes: dummyBytes,
          fileName: 'photo.jpg',
        ),
        throwsA(
          isA<AttachmentValidationException>().having(
            (e) => e.message,
            'message',
            contains('Work order ID cannot be empty'),
          ),
        ),
      );

      await expectLater(
        attachmentService.uploadAttachment(
          workOrderId: '   ',
          bytes: dummyBytes,
          fileName: 'photo.jpg',
        ),
        throwsA(isA<AttachmentValidationException>()),
      );
    });
  });
}
