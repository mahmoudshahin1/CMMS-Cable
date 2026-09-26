import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../outbox/outbox_command.dart';

/// Card displaying details and retry/dismiss actions for a single dead-letter command.
class DeadLetterCommandCard extends StatelessWidget {
  final OutboxCommand command;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const DeadLetterCommandCard({
    super.key,
    required this.command,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  command.commandType,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.blueGrey.withValues(alpha: 0.15),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${command.aggregateId}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Attempts: ${command.attempts}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          if (command.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                command.lastError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.energyaAccentOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
