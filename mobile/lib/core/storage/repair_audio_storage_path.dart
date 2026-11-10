/// Builds and validates private Storage keys for repair remarks audio.
///
/// Keys are scoped to one work order so Storage RLS can authorize access using
/// the first path segment. Local filesystem paths and absolute URLs are never
/// valid values for `repair_voice_url`.
class RepairAudioStoragePath {
  static const _directory = 'repair-voice-notes';
  static const _extensions = {'m4a', 'mp3', 'aac', 'wav', 'ogg'};

  static String forFile({
    required String workOrderId,
    required String fileName,
  }) {
    if (!_isSafeSegment(workOrderId) || !_isSafeFileName(fileName)) {
      throw const FormatException('Invalid repair audio Storage path parts.');
    }
    return '$workOrderId/$_directory/$fileName';
  }

  static bool isValid({required String workOrderId, required String path}) {
    if (!_isSafeSegment(workOrderId) || path.contains(r'\')) return false;
    final segments = path.split('/');
    final isCurrentPath =
        segments.length == 3 &&
        segments[0] == workOrderId &&
        segments[1] == _directory;
    final isLegacyPath =
        segments.length == 3 &&
        segments[0] == 'voice-notes' &&
        segments[1] == workOrderId;
    return (isCurrentPath || isLegacyPath) && _isSafeFileName(segments[2]);
  }

  static bool _isSafeSegment(String value) =>
      value.isNotEmpty &&
      value != '.' &&
      value != '..' &&
      !value.contains('/') &&
      !value.contains(r'\') &&
      !value.contains(':');

  static bool _isSafeFileName(String value) {
    if (!_isSafeSegment(value) || value.contains('?') || value.contains('#')) {
      return false;
    }
    final dot = value.lastIndexOf('.');
    if (dot <= 0 || dot == value.length - 1) return false;
    return _extensions.contains(value.substring(dot + 1).toLowerCase());
  }
}
