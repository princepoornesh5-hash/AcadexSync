import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authoritative India Standard Time (Asia/Kolkata: UTC+5:30) Engine and
/// minute-boundary scheduler for the ACADEX Live Clock.
///
/// Features:
/// - Authoritative calculation of Asia/Kolkata (IST) time
/// - Precise next-minute boundary scheduling (zero drift)
/// - App lifecycle observer (automatic reconciliation on app resume/focus)
/// - Missed-minute reconciliation (instant snap, never replays historical minutes)
/// - Midnight roll-over (23:59 -> 00:00) and hour roll-over validation
/// - Clean timer disposal with zero memory leaks
class AcadexTimeEngine with WidgetsBindingObserver {
  DateTime _currentIst;
  Timer? _boundaryTimer;
  bool _isDisposed = false;

  /// Callback fired when the actual minute boundary turns.
  /// Passes the previous IST time and the new IST time.
  final void Function(DateTime oldTime, DateTime newTime)? onMinuteChanged;

  /// Callback fired when time is reconciled after resume or manual update.
  final void Function(DateTime newTime)? onTimeReconciled;

  AcadexTimeEngine({
    this.onMinuteChanged,
    this.onTimeReconciled,
    DateTime? initialTime,
  }) : _currentIst = initialTime ?? nowIst() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextMinute();
  }

  /// Current India Standard Time (Asia/Kolkata: UTC + 5 hours 30 minutes).
  static DateTime nowIst() {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Authoritative current IST DateTime for this engine.
  DateTime get currentIst => _currentIst;

  /// 12-hour hour representation without leading zero (1 to 12).
  String get formattedHours => formatHours(_currentIst);

  /// 2-digit minute representation (00 to 59).
  String get formattedMinutes => formatMinutes(_currentIst);

  /// Period representation ('AM' or 'PM').
  String get formattedPeriod => formatPeriod(_currentIst);

  /// Complete 12-hour time string in 'h:mm AM/PM' format (e.g. '6:43 PM', '12:00 AM').
  String get formattedTime => formatTime(_currentIst);

  /// Converts a 24-hour value (0..23) to 12-hour value (1..12).
  static int to12Hour(int hour24) {
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  /// 12-hour format with no leading zero (1..12).
  static String formatHours(DateTime dt) => to12Hour(dt.hour).toString();

  /// 2-digit minute representation with zero padding (00..59).
  static String formatMinutes(DateTime dt) => dt.minute.toString().padLeft(2, '0');

  /// Period string ('AM' or 'PM').
  static String formatPeriod(DateTime dt) => dt.hour < 12 ? 'AM' : 'PM';

  /// Formats in 12-hour 'h:mm AM/PM' format (e.g. '9:05 AM', '6:43 PM').
  static String formatTime(DateTime dt) =>
      '${formatHours(dt)}:${formatMinutes(dt)} ${formatPeriod(dt)}';

  /// Calculates milliseconds remaining until the precise turn of the next IST minute.
  static Duration durationUntilNextMinute([DateTime? fromTime]) {
    final now = fromTime ?? nowIst();
    final secondsRemaining = 59 - now.second;
    final msRemaining = 999 - now.millisecond;
    // 25ms buffer to guarantee the clock has crossed the minute threshold
    final totalMs = (secondsRemaining * 1000) + msRemaining + 25;
    return Duration(milliseconds: math.max(40, totalMs));
  }

  void _scheduleNextMinute() {
    _boundaryTimer?.cancel();
    if (_isDisposed) return;

    final delay = durationUntilNextMinute(nowIst());
    _boundaryTimer = Timer(delay, _onMinuteBoundaryReached);
  }

  void _onMinuteBoundaryReached() {
    if (_isDisposed) return;

    final oldTime = _currentIst;
    final newTime = nowIst();
    _currentIst = newTime;

    // Reschedule immediately for the subsequent minute
    _scheduleNextMinute();

    // Trigger minute change callback
    onMinuteChanged?.call(oldTime, newTime);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reconcileTime();
    }
  }

  /// Reconciles current IST time after app resume, route change, or tab focus.
  /// Never replays missed animations; directly synchronizes if the minute changed.
  void reconcileTime() {
    if (_isDisposed) return;

    final realIst = nowIst();
    if (_currentIst.minute != realIst.minute || _currentIst.hour != realIst.hour) {
      _currentIst = realIst;
      _scheduleNextMinute();
      onTimeReconciled?.call(realIst);
    } else {
      _scheduleNextMinute();
    }
  }

  /// Test hook to simulate a minute change directly in unit tests or developer showcase.
  void simulateMinuteChange({DateTime? targetTime}) {
    if (_isDisposed) return;
    final oldTime = _currentIst;
    final newTime = targetTime ?? oldTime.add(const Duration(minutes: 1));
    _currentIst = newTime;
    _scheduleNextMinute();
    onMinuteChanged?.call(oldTime, newTime);
  }

  void dispose() {
    _isDisposed = true;
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Transition model capturing changes between two 12-hour clock states.
/// Detects specifically which visible components (Hour, Minute, AM/PM) changed.
class TimeDisplayChange {
  final String previousHour;
  final String currentHour;
  final String previousMinute;
  final String currentMinute;
  final String previousPeriod;
  final String currentPeriod;

  const TimeDisplayChange({
    required this.previousHour,
    required this.currentHour,
    required this.previousMinute,
    required this.currentMinute,
    required this.previousPeriod,
    required this.currentPeriod,
  });

  /// Factory creating a [TimeDisplayChange] from two DateTime instances.
  factory TimeDisplayChange.between(DateTime oldTime, DateTime newTime) {
    return TimeDisplayChange(
      previousHour: AcadexTimeEngine.formatHours(oldTime),
      currentHour: AcadexTimeEngine.formatHours(newTime),
      previousMinute: AcadexTimeEngine.formatMinutes(oldTime),
      currentMinute: AcadexTimeEngine.formatMinutes(newTime),
      previousPeriod: AcadexTimeEngine.formatPeriod(oldTime),
      currentPeriod: AcadexTimeEngine.formatPeriod(newTime),
    );
  }

  bool get hourChanged => previousHour != currentHour;
  bool get minuteChanged => previousMinute != currentMinute;
  bool get periodChanged => previousPeriod != currentPeriod;
  bool get hasChanges => hourChanged || minuteChanged || periodChanged;
  bool get hasAnyChange => hasChanges;

  String get previousHours => previousHour;
  String get currentHours => currentHour;
  String get previousMinutes => previousMinute;
  String get currentMinutes => currentMinute;

  @override
  String toString() =>
      'TimeDisplayChange($previousHour:$previousMinute $previousPeriod -> $currentHour:$currentMinute $currentPeriod, '
      'hChanged: $hourChanged, mChanged: $minuteChanged, pChanged: $periodChanged)';
}
