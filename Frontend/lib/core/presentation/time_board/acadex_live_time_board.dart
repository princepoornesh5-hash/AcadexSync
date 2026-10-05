import 'package:flutter/material.dart';
import 'acadex_scoreboard_card.dart';
import 'acadex_time_engine.dart';

/// Live mechanical split-flap time board for 12-hour h:mm AM/PM India Standard Time.
///
/// Features:
/// - Self-contained, character-free mechanical clock
/// - Component-aware transition animation:
///   - Animates ONLY the components that actually changed (Hour, Minute, AM/PM)
///   - Stable components remain 100% calm and static
/// - Synchronized mechanical wipe -> blank -> progressive write/reveal
/// - Seamless 12-hour transitions:
///   - Minute-only: 6:42 PM -> 6:43 PM
///   - Hour + Minute: 6:59 PM -> 7:00 PM
///   - Noon roll-over: 11:59 AM -> 12:00 PM
///   - Afternoon roll-over: 12:59 PM -> 1:00 PM
///   - Midnight roll-over: 11:59 PM -> 12:00 AM
///   - Single-digit to double-digit hour: 9:59 AM -> 10:00 AM
/// - Zero continuous animation while time is stable
/// - Full reduced-motion and lifecycle safety
class AcadexLiveTimeBoard extends StatefulWidget {
  final String? userName;
  final bool isCompact;
  final DateTime? initialTime;
  final VoidCallback? onMinuteSequenceFinished;

  const AcadexLiveTimeBoard({
    super.key,
    this.userName,
    this.isCompact = false,
    this.initialTime,
    this.onMinuteSequenceFinished,
  });

  @override
  State<AcadexLiveTimeBoard> createState() => AcadexLiveTimeBoardState();
}

class AcadexLiveTimeBoardState extends State<AcadexLiveTimeBoard>
    with SingleTickerProviderStateMixin {
  late AcadexTimeEngine _timeEngine;
  late final AnimationController _transitionController;

  String _currentHours = '12';
  String _currentMinutes = '00';
  String _currentPeriod = 'AM';
  String? _oldHours;
  String? _oldMinutes;
  String? _oldPeriod;

  bool _isSequenceRunning = false;
  bool get isTransitioning => _isSequenceRunning;
  double _wipeProgress = 0.0;
  double _writeProgress = 1.0;
  bool _isWiping = false;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();

    // Polished mechanical transition duration: 1200ms
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _transitionController.addListener(_onTransitionTick);
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSequenceCompleted();
      }
    });

    _timeEngine = AcadexTimeEngine(
      initialTime: widget.initialTime,
      onMinuteChanged: _onMinuteChanged,
      onTimeReconciled: _onTimeReconciled,
    );

    _currentHours = _timeEngine.formattedHours;
    _currentMinutes = _timeEngine.formattedMinutes;
    _currentPeriod = _timeEngine.formattedPeriod;
  }

  /// Sets the static board time immediately without running animation
  void setTime(DateTime time) {
    if (_isSequenceRunning) {
      _transitionController.stop();
      _isSequenceRunning = false;
    }
    _timeEngine.dispose();
    _timeEngine = AcadexTimeEngine(
      initialTime: time,
      onMinuteChanged: _onMinuteChanged,
      onTimeReconciled: _onTimeReconciled,
    );
    setState(() {
      _currentHours = _timeEngine.formattedHours;
      _currentMinutes = _timeEngine.formattedMinutes;
      _currentPeriod = _timeEngine.formattedPeriod;
      _oldHours = null;
      _oldMinutes = null;
      _oldPeriod = null;
      _isWiping = false;
      _isWriting = false;
      _writeProgress = 1.0;
      _wipeProgress = 0.0;
    });
  }

  void _onMinuteChanged(DateTime oldTime, DateTime newTime) {
    if (!mounted) return;

    final change = TimeDisplayChange.between(oldTime, newTime);
    if (!change.hasChanges) return;

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      setState(() {
        _currentHours = change.currentHour;
        _currentMinutes = change.currentMinute;
        _currentPeriod = change.currentPeriod;
        _oldHours = null;
        _oldMinutes = null;
        _oldPeriod = null;
        _isSequenceRunning = false;
        _isWiping = false;
        _isWriting = false;
        _writeProgress = 1.0;
        _wipeProgress = 0.0;
      });
      widget.onMinuteSequenceFinished?.call();
      return;
    }

    _startTransitionSequence(change);
  }

  void _onTimeReconciled(DateTime newTime) {
    if (!mounted) return;
    setState(() {
      _currentHours = AcadexTimeEngine.formatHours(newTime);
      _currentMinutes = AcadexTimeEngine.formatMinutes(newTime);
      _currentPeriod = AcadexTimeEngine.formatPeriod(newTime);
    });
  }

  /// Programmatic trigger for testing and visual preview
  void triggerMinuteChange({DateTime? nextTime}) {
    if (_isSequenceRunning) return;
    _timeEngine.simulateMinuteChange(targetTime: nextTime);
  }

  void _startTransitionSequence(TimeDisplayChange change) {
    if (_isSequenceRunning) {
      _transitionController.stop();
    }

    setState(() {
      _isSequenceRunning = true;
      _oldHours = change.previousHour;
      _oldMinutes = change.previousMinute;
      _oldPeriod = change.previousPeriod;
      _currentHours = change.currentHour;
      _currentMinutes = change.currentMinute;
      _currentPeriod = change.currentPeriod;
      _wipeProgress = 0.0;
      _writeProgress = 0.0;
      _isWiping = false;
      _isWriting = false;
    });

    _transitionController.forward(from: 0.0);
  }

  void _onTransitionTick() {
    final t = _transitionController.value;

    // Timeline breakdown (Total: 1200ms):
    // 0.00 -> 0.40 : Phase 1 - Mechanical Wipe (old digits erased with luminous line)
    // 0.40 -> 0.50 : Phase 2 - Blank State (affected flaps completely empty)
    // 0.50 -> 0.95 : Phase 3 - Progressive Reveal / Write (new digits formed)
    // 0.95 -> 1.00 : Phase 4 - Settle (crisp static calm state)

    if (t < 0.40) {
      final p = (t / 0.40).clamp(0.0, 1.0);
      final wipeCurve = Curves.easeInOutCubic.transform(p);
      _isWiping = true;
      _isWriting = false;
      _wipeProgress = wipeCurve;
      _writeProgress = 0.0;
    } else if (t < 0.50) {
      _isWiping = false;
      _isWriting = true;
      _wipeProgress = 1.0;
      _writeProgress = 0.0;
    } else if (t < 0.95) {
      final p = ((t - 0.50) / 0.45).clamp(0.0, 1.0);
      final writeCurve = Curves.easeOutCubic.transform(p);
      _isWiping = false;
      _isWriting = true;
      _wipeProgress = 1.0;
      _writeProgress = writeCurve;
    } else {
      _isWiping = false;
      _isWriting = true;
      _wipeProgress = 1.0;
      _writeProgress = 1.0;
    }

    if (mounted) setState(() {});
  }

  void _onSequenceCompleted() {
    setState(() {
      _isSequenceRunning = false;
      _oldHours = null;
      _oldMinutes = null;
      _oldPeriod = null;
      _isWiping = false;
      _isWriting = false;
      _writeProgress = 1.0;
      _wipeProgress = 0.0;
    });

    widget.onMinuteSequenceFinished?.call();
  }

  @override
  void dispose() {
    _timeEngine.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live clock. Current time $_currentHours:$_currentMinutes $_currentPeriod India Standard Time',
      child: GestureDetector(
        onTap: () {
          if (!_isSequenceRunning) {
            triggerMinuteChange();
          }
        },
        child: AcadexScoreboardCard(
          hours: _currentHours,
          minutes: _currentMinutes,
          period: _currentPeriod,
          oldHours: _oldHours,
          oldMinutes: _oldMinutes,
          oldPeriod: _oldPeriod,
          wipeProgress: _wipeProgress,
          writeProgress: _writeProgress,
          isWiping: _isWiping,
          isWriting: _isWriting,
          isCompact: widget.isCompact,
        ),
      ),
    );
  }
}
