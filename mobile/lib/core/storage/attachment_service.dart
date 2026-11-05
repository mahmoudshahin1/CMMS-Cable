import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Exceptions thrown during attachment operations.
class AttachmentValidationException implements Exception {
  final String message;
  const AttachmentValidationException(this.message);
  @override
  String toString() => 'AttachmentValidationException: $message';
}

/// Service managing work order fault photos & voice note uploads and signed URLs.
class AttachmentService {
  static const String bucketName = 'work-order-attachments';
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB limit
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> allowedVoiceExtensions = {
    '.m4a',
    '.mp3',
    '.aac',
    '.wav',
    '.ogg',
  };
  static const _uuid = Uuid();

  final SupabaseClient? _client;

  AttachmentService({SupabaseClient? client}) : _client = client;

  SupabaseClient get _effectiveClient => _client ?? Supabase.instance.client;

  /// Validates photo attachment file size and format.
  void validateAttachment({
    required int sizeBytes,
    required String fileName,
  }) {
    if (sizeBytes <= 0) {
      throw const AttachmentValidationException('Attachment file cannot be empty.');
    }
    if (sizeBytes > maxFileSizeBytes) {
      throw AttachmentValidationException(
        'Attachment exceeds maximum 10MB limit (${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)}MB).',
      );
    }

    final ext = _extractExtension(fileName);
    if (!allowedExtensions.contains(ext)) {
      throw AttachmentValidationException(
        'Disallowed file extension "$ext". Permitted: ${allowedExtensions.join(", ")}',
      );
    }
  }

  /// Validates voice note file size and format.
  void validateVoiceNote({
    required int sizeBytes,
    required String fileName,
  }) {
    if (sizeBytes <= 0) {
      throw const AttachmentValidationException('Voice note file cannot be empty.');
    }
    if (sizeBytes > maxFileSizeBytes) {
      throw AttachmentValidationException(
        'Voice note exceeds maximum 10MB limit (${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)}MB).',
      );
    }

    final ext = _extractExtension(fileName);
    if (!allowedVoiceExtensions.contains(ext)) {
      throw AttachmentValidationException(
        'Disallowed voice format "$ext". Permitted: ${allowedVoiceExtensions.join(", ")}',
      );
    }
  }

  /// Uploads binary photo to dedicated Supabase Storage bucket.
  Future<String> uploadAttachment({
    required String workOrderId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    if (workOrderId.trim().isEmpty) {
      throw const AttachmentValidationException('Work order ID cannot be empty.');
    }

    validateAttachment(sizeBytes: bytes.length, fileName: fileName);

    final ext = _extractExtension(fileName);
    final uniqueId = _uuid.v4();
    final storagePath = '$workOrderId/$uniqueId$ext';
    final resolvedMime = mimeType ?? _inferMimeType(ext);

    debugPrint('📤 AttachmentService: uploading ${bytes.length} bytes to $bucketName/$storagePath');

    await _effectiveClient.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: resolvedMime,
            upsert: false,
          ),
        );

    debugPrint('✅ AttachmentService: successfully uploaded $storagePath');
    return storagePath;
  }

  /// Uploads binary audio voice note to existing 'work-order-attachments' bucket with prefix.
  Future<String> uploadVoiceNote({
    required String workOrderId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    if (workOrderId.trim().isEmpty) {
      throw const AttachmentValidationException('Work order ID cannot be empty.');
    }

    validateVoiceNote(sizeBytes: bytes.length, fileName: fileName);

    final ext = _extractExtension(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'voice-notes/$workOrderId/$timestamp$ext';
    final resolvedMime = mimeType ?? _inferAudioMimeType(ext);

    debugPrint('📤 AttachmentService: uploading voice ${bytes.length} bytes to $bucketName/$storagePath');

    await _effectiveClient.storage.from(bucketName).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: resolvedMime,
            upsert: false,
          ),
        );

    debugPrint('✅ AttachmentService: successfully uploaded voice note $storagePath');
    return storagePath;
  }

  /// Generates a short-lived signed URL for secure private viewing or listening.
  Future<String> getSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) async {
    return _effectiveClient.storage
        .from(bucketName)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  /// Removes attachment from storage bucket.
  Future<void> deleteAttachment(String storagePath) async {
    await _effectiveClient.storage.from(bucketName).remove([storagePath]);
  }

  String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _inferMimeType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _inferAudioMimeType(String ext) {
    switch (ext) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
      case '.aac':
      default:
        return 'audio/mp4';
    }
  }
}
