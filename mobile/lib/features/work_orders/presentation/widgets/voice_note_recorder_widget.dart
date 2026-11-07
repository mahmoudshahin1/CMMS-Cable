import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/storage/attachment_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'voice_note_player_view.dart';

/// Records voice notes to an app-private file so they survive offline submission.
class VoiceNoteRecorderWidget extends StatefulWidget {
  final String label;
  final String? initialAudioUrl;
  final bool isEditable;
  final String? workOrderId;
  final ValueChanged<String?> onAudioUrlChanged;
  final Future<String?> Function(Uint8List bytes, String fileName)?
  onUploadAudio;

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
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _audioUrl;
  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordDuration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _recordTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _audioUrl = widget.initialAudioUrl;
    _positionSub = _player.positionStream.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _durationSub = _player.durationStream.listen((value) {
      if (mounted) setState(() => _duration = value ?? Duration.zero);
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        setState(() => _position = Duration.zero);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VoiceNoteRecorderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAudioUrl != oldWidget.initialAudioUrl) {
      _audioUrl = widget.initialAudioUrl;
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _showMessage(
          'Microphone permission is required to record a voice note.',
        );
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}'
          'voice_note_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: filePath,
      );
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        }
      });
    } catch (error) {
      _showMessage('Could not start recording: $error');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isUploading = true;
    });
    try {
      final recordedPath = await _recorder.stop();
      if (recordedPath == null) {
        throw StateError('The recorder did not produce an audio file.');
      }
      final recordedFile = File(recordedPath);
      if (!await recordedFile.exists() || await recordedFile.length() == 0) {
        throw StateError('The recorded audio file is empty.');
      }

      // Tests and integrations may inject an uploader. Normal reporting keeps the
      // file local; the outbox uploads it after the work order has been created.
      final resolvedPath = widget.onUploadAudio == null
          ? recordedPath
          : await widget.onUploadAudio!(
              await recordedFile.readAsBytes(),
              'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
            );
      if (resolvedPath == null) {
        throw StateError('Voice note upload returned no storage path.');
      }
      if (!mounted) return;
      setState(() {
        _audioUrl = resolvedPath;
        _isRecording = false;
      });
      widget.onAudioUrlChanged(resolvedPath);
    } catch (error) {
      if (mounted) {
        setState(() => _isRecording = false);
        _showMessage('Could not save the voice note: $error');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }
      final audio = _audioUrl;
      if (audio == null) return;
      if (audio.startsWith('http://') || audio.startsWith('https://')) {
        await _player.setUrl(audio);
      } else if (await File(audio).exists()) {
        await _player.setFilePath(audio);
      } else {
        final signedUrl = await AttachmentService().getSignedUrl(audio);
        await _player.setUrl(signedUrl);
      }
      await _player.play();
    } catch (error) {
      _showMessage('Could not play the voice note: $error');
    }
  }

  Future<void> _deleteAudio() async {
    await _player.stop();
    final audio = _audioUrl;
    if (audio != null && await File(audio).exists()) {
      await File(audio).delete();
    }
    if (!mounted) return;
    setState(() {
      _audioUrl = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    widget.onAudioUrlChanged(null);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              Icon(
                Icons.mic_none_rounded,
                size: 16,
                color: context.brandPrimary,
              ),
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
              player: _player,
              position: _position,
              duration: _duration,
              isEditable: widget.isEditable && !_isUploading,
              onTogglePlayback: _togglePlayback,
              onDeleteAudio: _deleteAudio,
            )
          else if (_isRecording)
            VoiceNoteRecordingView(
              recordSeconds: _recordDuration.inSeconds,
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
      onTap: _isUploading ? null : _startRecording,
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
