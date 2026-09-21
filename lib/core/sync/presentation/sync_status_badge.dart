import 'dart:async';
import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../theme/app_colors.dart';
import '../outbox/outbox_local_data_source.dart';
import '../outbox/outbox_sync_engine.dart';
import 'dead_letter_inspector_dialog.dart';

/// Industrial badge displaying real-time offline sync status and outbox backlog.
class SyncStatusBadge extends StatefulWidget {
  final OutboxSyncEngine? syncEngine;
  final OutboxLocalDataSource? outboxLocal;

  const SyncStatusBadge({
    super.key,
    this.syncEngine,
    this.outboxLocal,
  });

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late final OutboxSyncEngine _syncEngine;
  late final OutboxLocalDataSource _outboxLocal;

  SyncEngineState _engineState = SyncEngineState.idle;
  int _pendingCount = 0;
  int _deadLetterCount = 0;

  StreamSubscription<SyncEngineState>? _stateSub;
  StreamSubscription<int>? _countSub;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _syncEngine = widget.syncEngine ?? getIt<OutboxSyncEngine>();
    _outboxLocal = widget.outboxLocal ?? getIt<OutboxLocalDataSource>();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _stateSub = _syncEngine.stateStream.listen((state) {
      if (mounted) {
        setState(() => _engineState = state);
        if (state == SyncEngineState.syncing) {
          _animController.repeat();
        } else {
          _animController.stop();
          _animController.reset();
        }
      }
    });

    _countSub = _syncEngine.pendingCountStream.listen((count) {
      if (mounted) {
        setState(() => _pendingCount = count);
        _refreshDeadLetterCount();
      }
    });

    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final pending = await _outboxLocal.getPendingCount();
    final dead = (await _outboxLocal.getDeadLetterCommands()).length;
    if (mounted) {
      setState(() {
        _pendingCount = pending;
        _deadLetterCount = dead;
      });
    }
  }

  Future<void> _refreshDeadLetterCount() async {
    final dead = (await _outboxLocal.getDeadLetterCommands()).length;
    if (mounted) {
      setState(() => _deadLetterCount = dead);
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _countSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_deadLetterCount > 0) {
      DeadLetterInspectorDialog.show(context).then((_) => _refreshCounts());
    } else {
      _syncEngine.syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Triggered background synchronization'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deadLetterCount > 0) {
      return _buildPill(
        icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
        label: '$_deadLetterCount issue(s)',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        tooltip: 'Outbox errors detected. Tap to inspect and resolve.',
      );
    }

    if (_engineState == SyncEngineState.syncing) {
      return _buildPill(
        icon: RotationTransition(
          turns: _animController,
          child: const Icon(Icons.sync, size: 14, color: Colors.white),
        ),
        label: _pendingCount > 0 ? 'Syncing ($_pendingCount)' : 'Syncing...',
        backgroundColor: AppColors.energyaPrimaryBlue,
        textColor: Colors.white,
        tooltip: 'Synchronizing mutations with Supabase Cloud...',
      );
    }

    if (_engineState == SyncEngineState.offline) {
      return _buildPill(
        icon: const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.white),
        label: _pendingCount > 0 ? 'Offline ($_pendingCount)' : 'Offline',
        backgroundColor: Colors.orange.shade800,
        textColor: Colors.white,
        tooltip: 'Working offline. Changes queued in local Hive outbox.',
      );
    }

    if (_pendingCount > 0) {
      return _buildPill(
        icon: const Icon(Icons.upload_rounded, size: 14, color: Colors.white),
        label: 'Queued ($_pendingCount)',
        backgroundColor: Colors.blueGrey.shade700,
        textColor: Colors.white,
        tooltip: 'Pending upload to Supabase. Tap to sync now.',
      );
    }

    return _buildPill(
      icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.greenAccent),
      label: 'Synced',
      backgroundColor: Colors.green.withValues(alpha: 0.15),
      textColor: Colors.green,
      tooltip: 'All local changes synchronized with cloud.',
    );
  }

  Widget _buildPill({
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
