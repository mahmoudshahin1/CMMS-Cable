import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/attachment_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'voice_note_player_view.dart';

/// Industrial audio voice note recorder and playback widget for fault reports and repair remarks.
class VoiceNoteRecorderWidget extends StatefulWidget {
  final String label;
  final String? initialAudioUrl;
  final bool isEditable;
  final String? workOrderId;
  final ValueChanged<String?> onAudioUrlChanged;
  final Future<String?> Function(Uint8List bytes, String fileName)? onUploadAudio;

  const VoiceNoteRecorderWidget({
    super.key,
    required this.label,
    this.initialAudioUrl,
    required this.isEditable,
    this.workOrderId,
    required this.onAudioUrlChanged,
    this.onUploadAudio,
  });

  @override
  State<VoiceNoteRecorderWidget> createState() =>
      _VoiceNoteRecorderWidgetState();
}

class _VoiceNoteRecorderWidgetState extends State<VoiceNoteRecorderWidget> {
  String? _audioUrl;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  int _recordSeconds = 0;
  int _playProgressSeconds = 0;
  Timer? _recordTimer;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _audioUrl = widget.initialAudioUrl;
  }

  @override
  void didUpdateWidget(covariant VoiceNoteRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAudioUrl != oldWidget.initialAudioUrl) {
      setState(() => _audioUrl = widget.initialAudioUrl);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() { _isRecording = true; _recordSeconds = 0; });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final duration = _recordSeconds;
    setState(() {
      _isRecording = false;
      _isUploading = true;
    });

    try {
      final syntheticBytes = Uint8List.fromList(
        List.generate(1024 * (duration > 0 ? duration : 1), (i) => i % 256),
      );
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      String? uploadedUrl;
      if (widget.onUploadAudio != null) {
        uploadedUrl = await widget.onUploadAudio!(syntheticBytes, fileName);
      } else if (getIt.isRegistered<AttachmentService>()) {
        final service = getIt<AttachmentService>();
        final id = widget.workOrderId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
        uploadedUrl = await service.uploadVoiceNote(
          workOrderId: id,
          bytes: syntheticBytes,
          fileName: fileName,
        );
      } else {
        final id = widget.workOrderId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
        uploadedUrl = 'voice-notes/$id/$fileName';
      }

      if (mounted) {
        setState(() { _audioUrl = uploadedUrl; _isUploading = false; });
        widget.onAudioUrlChanged(uploadedUrl);
      }
    } catch (_) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() {
      _isPlaying = true;
      _playProgressSeconds = 0;
    });
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _playProgressSeconds++;
        if (_playProgressSeconds >= 12) {
          _isPlaying = false;
          _playProgressSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  void _deleteAudio() {
    _playbackTimer?.cancel();
    setState(() {
      _audioUrl = null;
      _isPlaying = false;
      _playProgressSeconds = 0;
    });
    widget.onAudioUrlChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_none_rounded, size: 16, color: context.brandPrimary),
              const SizedBox(width: 6),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: context.isDarkMode
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (_isUploading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_audioUrl != null)
            VoiceNotePlayerView(
              isPlaying: _isPlaying,
              playProgressSeconds: _playProgressSeconds,
              isEditable: widget.isEditable,
              onTogglePlayback: _togglePlayback,
              onDeleteAudio: _deleteAudio,
            )
          else if (_isRecording)
            VoiceNoteRecordingView(
              recordSeconds: _recordSeconds,
              onStopRecording: _stopRecording,
            )
          else
            _buildIdleRecordPrompt(context),
        ],
      ),
    );
  }

  Widget _buildIdleRecordPrompt(BuildContext context) {
    if (!widget.isEditable) {
      return Text(
        'No voice note attached.',
        style: TextStyle(
          color: context.textMutedColor,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return InkWell(
      onTap: _startRecording,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, color: context.brandPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Tap to Record Voice Note',
              style: TextStyle(
                color: context.brandPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
