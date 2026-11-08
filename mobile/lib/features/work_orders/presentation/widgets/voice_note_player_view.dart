import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';

/// Playback controls backed by the real audio player's position and duration.
class VoiceNotePlayerView extends StatelessWidget {
  final AudioPlayer player;
  final Duration position;
  final Duration duration;
  final bool isEditable;
  final VoidCallback onTogglePlayback;
  final VoidCallback onDeleteAudio;

  const VoiceNotePlayerView({
    super.key,
    required this.player,
    required this.position,
    required this.duration,
    required this.isEditable,
    required this.onTogglePlayback,
    required this.onDeleteAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return IconButton(
              onPressed: onTogglePlayback,
              icon: Icon(
                playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: context.brandPrimary,
                size: 32,
              ),
            );
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: duration.inMilliseconds == 0
                      ? 0
                      : position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                  min: 0,
                  max: duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1,
                  activeColor: context.brandPrimary,
                  onChanged: duration.inMilliseconds == 0
                      ? null
                      : (value) =>
                            player.seek(Duration(milliseconds: value.round())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_format(position)} / ${_format(duration)}',
                  style: TextStyle(color: context.textMutedColor, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        if (isEditable)
          IconButton(
            onPressed: onDeleteAudio,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.downMaintenanceRed,
              size: 20,
            ),
          ),
      ],
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Active recording timer with an explicit stop action.
class VoiceNoteRecordingView extends StatelessWidget {
  final int recordSeconds;
  final VoidCallback onStopRecording;

  const VoiceNoteRecordingView({
    super.key,
    required this.recordSeconds,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: recordSeconds);
    final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(
          Icons.fiber_manual_record,
          color: AppColors.downMaintenanceRed,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          'Recording: $mm:$ss',
          style: const TextStyle(
            color: AppColors.downMaintenanceRed,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onStopRecording,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.downMaintenanceRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          icon: const Icon(Icons.stop, size: 16),
          label: const Text('Stop & Save', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
