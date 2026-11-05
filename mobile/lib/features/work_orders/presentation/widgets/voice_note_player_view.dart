import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Player controls and progress bar for voice note playback.
class VoiceNotePlayerView extends StatelessWidget {
  final bool isPlaying;
  final int playProgressSeconds;
  final bool isEditable;
  final VoidCallback onTogglePlayback;
  final VoidCallback onDeleteAudio;

  const VoiceNotePlayerView({
    super.key,
    required this.isPlaying,
    required this.playProgressSeconds,
    required this.isEditable,
    required this.onTogglePlayback,
    required this.onDeleteAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onTogglePlayback,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: context.brandPrimary,
            size: 32,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isPlaying ? (playProgressSeconds / 12) : 0.0,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation(context.brandPrimary),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Audio: 0:${playProgressSeconds.toString().padLeft(2, "0")} / 0:12',
                style: TextStyle(color: context.textMutedColor, fontSize: 11),
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
}

/// Active recording visualizer with timer and stop action button.
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
    return Row(
      children: [
        const Icon(
          Icons.fiber_manual_record,
          color: AppColors.downMaintenanceRed,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          'Recording: 0:${recordSeconds.toString().padLeft(2, "0")}',
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
