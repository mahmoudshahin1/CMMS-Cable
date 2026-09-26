import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../theme/app_colors.dart';
import '../outbox/outbox_command.dart';
import '../outbox/outbox_local_data_source.dart';
import '../outbox/outbox_sync_engine.dart';
import 'dead_letter_command_card.dart';

/// Modal dialog for reviewing and resolving failed/dead-letter outbox commands.
class DeadLetterInspectorDialog extends StatefulWidget {
  final OutboxLocalDataSource? outboxLocal;
  final OutboxSyncEngine? syncEngine;

  const DeadLetterInspectorDialog({
    super.key,
    this.outboxLocal,
    this.syncEngine,
  });

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const DeadLetterInspectorDialog(),
    );
  }

  @override
  State<DeadLetterInspectorDialog> createState() =>
      _DeadLetterInspectorDialogState();
}

class _DeadLetterInspectorDialogState extends State<DeadLetterInspectorDialog> {
  late final OutboxLocalDataSource _outboxLocal;
  late final OutboxSyncEngine _syncEngine;

  List<OutboxCommand> _deadLetters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _outboxLocal = widget.outboxLocal ?? getIt<OutboxLocalDataSource>();
    _syncEngine = widget.syncEngine ?? getIt<OutboxSyncEngine>();
    _loadDeadLetters();
  }

  Future<void> _loadDeadLetters() async {
    setState(() => _isLoading = true);
    final items = await _outboxLocal.getDeadLetterCommands();
    if (mounted) {
      setState(() {
        _deadLetters = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _retryCommand(OutboxCommand cmd) async {
    final resetCmd = cmd.copyWith(
      status: OutboxCommandStatus.pending,
      attempts: 0,
      lastError: null,
    );
    await _outboxLocal.enqueue(resetCmd);
    await _loadDeadLetters();
    _syncEngine.syncNow();
  }

  Future<void> _dismissCommand(String commandId) async {
    await _outboxLocal.deleteCommand(commandId);
    await _loadDeadLetters();
  }

  Future<void> _retryAll() async {
    for (final cmd in _deadLetters) {
      await _retryCommand(cmd);
    }
  }

  Future<void> _dismissAll() async {
    for (final cmd in _deadLetters) {
      await _outboxLocal.deleteCommand(cmd.commandId);
    }
    await _loadDeadLetters();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkNavy : Colors.white;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context)),
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sync_problem_rounded,
              color: Colors.red, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sync Dead-Letter Queue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${_deadLetters.length} failure(s) requiring operator review',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_deadLetters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text('No dead-letter commands found',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 4),
            Text('All offline mutations synchronized successfully',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _deadLetters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final cmd = _deadLetters[i];
        return DeadLetterCommandCard(
          command: cmd,
          onRetry: () => _retryCommand(cmd),
          onDismiss: () => _dismissCommand(cmd.commandId),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_deadLetters.isEmpty) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _dismissAll,
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('Dismiss All', style: TextStyle(fontSize: 12)),
        ),
        ElevatedButton.icon(
          onPressed: _retryAll,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry All', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.energyaPrimaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
