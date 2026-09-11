import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/chronology/event_chronology.dart';
import 'chronology/shift_chronology_compact_chip.dart';
import 'chronology/shift_chronology_expanded_card.dart';

class ShiftChronologyBadge extends StatefulWidget {
  /// If provided, displays this static chronology snapshot (e.g. For historical logs).
  /// If null, runs in live mode showing real-time plant shift and ticking plant clock.
  final EventChronology? chronology;

  /// If true, displays a compact single-line chip.
  final bool compact;

  /// Optional label prefix (e.g. "Record Time" or "Current Shift")
  final String? label;

  const ShiftChronologyBadge({
    super.key,
    this.chronology,
    this.compact = false,
    this.label,
  });

  @override
  State<ShiftChronologyBadge> createState() => _ShiftChronologyBadgeState();
}

class _ShiftChronologyBadgeState extends State<ShiftChronologyBadge> {
  Timer? _ticker;
  late EventChronology _current;

  @override
  void initState() {
    super.initState();
    _current = widget.chronology ?? EventChronology.now();
    if (widget.chronology == null) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _current = EventChronology.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShiftChronologyBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chronology != null) {
      _current = widget.chronology!;
      _ticker?.cancel();
      _ticker = null;
    } else if (_ticker == null) {
      _current = EventChronology.now();
      _startTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return ShiftChronologyCompactChip(chronology: _current);
    }

    return ShiftChronologyExpandedCard(
      chronology: _current,
      isLive: widget.chronology == null,
    );
  }
}
