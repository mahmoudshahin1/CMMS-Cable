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

/// Service managing work order fault photo uploads, signed URLs, and storage isolation.
class AttachmentService {
  static const String bucketName = 'work-order-attachments';
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB limit
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const _uuid = Uuid();

  final SupabaseClient _client;

  AttachmentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Validates file size and format against strict industrial CMMS constraints.
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

  /// Uploads binary photo to dedicated Supabase Storage bucket.
  /// Returns the relative storage path: `<workOrderId>/<uuid>.<ext>`.
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

    await _client.storage.from(bucketName).uploadBinary(
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

  /// Generates a short-lived signed URL for secure private viewing.
  Future<String> getSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600, // 1 hour default
  }) async {
    return _client.storage
        .from(bucketName)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  /// Removes attachment from storage bucket.
  Future<void> deleteAttachment(String storagePath) async {
    await _client.storage.from(bucketName).remove([storagePath]);
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
}
