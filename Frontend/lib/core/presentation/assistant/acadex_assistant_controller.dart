import 'dart:async';
import 'package:flutter/material.dart';
import 'acadex_assistant_types.dart';

/// Controller managing pose, expression, gaze, and choreographed actions
/// for the canonical ACADEX Assistant character.
///
/// Supports smooth transitions, multi-step actions (greeting, wave, magic,
/// wipe, write, appear, disappear), and clean disposal.
class AcadexAssistantController extends ChangeNotifier {
  AcadexAssistantPose _pose = AcadexAssistantPose.idle;
  AcadexAssistantExpression _expression = AcadexAssistantExpression.defaultExpression;
  Offset _gazeDirection = Offset.zero;
  double _poseProgress = 0.0;
  double _visibility = 1.0;
  double _magicSparkleProgress = 0.0;
  Offset? _stylusTarget;
  bool _isActionRunning = false;
  Timer? _actionTimer;

  // Getters
  AcadexAssistantPose get pose => _pose;
  AcadexAssistantExpression get expression => _expression;
  Offset get gazeDirection => _gazeDirection;
  double get poseProgress => _poseProgress;
  double get visibility => _visibility;
  double get magicSparkleProgress => _magicSparkleProgress;
  Offset? get stylusTarget => _stylusTarget;
  bool get isActionRunning => _isActionRunning;
  bool get isVisible => _visibility > 0.01;

  AcadexAssistantController({
    AcadexAssistantPose initialPose = AcadexAssistantPose.idle,
    AcadexAssistantExpression initialExpression = AcadexAssistantExpression.defaultExpression,
    double initialVisibility = 1.0,
    Offset? initialStylusTarget,
  })  : _pose = initialPose,
        _expression = initialExpression,
        _visibility = initialVisibility,
        _stylusTarget = initialStylusTarget;

  /// Sets the active handwriting/wiping stylus target in local assistant coordinates.
  void setStylusTarget(Offset? target, {bool notify = false}) {
    if (_stylusTarget != target) {
      _stylusTarget = target;
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Update pose progress directly (called by the animation loop inside the widget).
  void updateProgress(double progress, {bool notify = false}) {
    if (_poseProgress != progress) {
      _poseProgress = progress;
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Sets the assistant's pose immediately and optionally updates expression.
  void setPose(
    AcadexAssistantPose newPose, {
    AcadexAssistantExpression? expression,
    bool resetProgress = true,
  }) {
    _cancelActionTimer();
    _pose = newPose;
    if (expression != null) {
      _expression = expression;
    }
    if (resetProgress) {
      _poseProgress = 0.0;
    }
    _magicSparkleProgress = (newPose == AcadexAssistantPose.magic) ? _magicSparkleProgress : 0.0;
    notifyListeners();
  }

  /// Sets the assistant's facial expression.
  void setExpression(AcadexAssistantExpression newExpression) {
    if (_expression != newExpression) {
      _expression = newExpression;
      notifyListeners();
    }
  }

  /// Directs the assistant's gaze toward a target offset (-1.0 to +1.0).
  void lookAt(Offset direction) {
    final clamped = Offset(
      direction.dx.clamp(-1.0, 1.0),
      direction.dy.clamp(-1.0, 1.0),
    );
    if (_gazeDirection != clamped) {
      _gazeDirection = clamped;
      notifyListeners();
    }
  }

  /// Plays a warm, welcoming greeting sequence:
  /// - Character looks toward user
  /// - Friendly expression & subtle nod
  /// - Small friendly hand wave
  /// - Settles back to calm idle
  void playGreeting({
    Duration duration = const Duration(milliseconds: 2600),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.greet;
    _expression = AcadexAssistantExpression.greeting;
    _gazeDirection = Offset.zero;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _pose = AcadexAssistantPose.idle;
        _expression = AcadexAssistantExpression.friendly;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Plays a dedicated hand-waving sequence with smooth side-to-side oscillation.
  void playWave({
    Duration duration = const Duration(milliseconds: 2000),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.wave;
    _expression = AcadexAssistantExpression.happy;
    _gazeDirection = Offset.zero;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _pose = AcadexAssistantPose.idle;
        _expression = AcadexAssistantExpression.friendly;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Plays the signature ACADEX Assistant Magic Gesture:
  /// - Raises right hand gracefully with finger flourish
  /// - Smiles with confident focused expression
  /// - Emits expanding luminous sapphire/cyan stardust aura and sparkle ring
  /// - Calls [onSparklePeak] at maximum flourish
  /// - Settles gracefully back to calm stance
  void playMagicGesture({
    Duration totalDuration = const Duration(milliseconds: 2400),
    VoidCallback? onSparklePeak,
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.magic;
    _expression = AcadexAssistantExpression.success;
    _magicSparkleProgress = 0.0;
    _poseProgress = 0.0;
    notifyListeners();

    // Trigger peak sparkle callback midway (~900ms)
    final peakTimer = Timer(const Duration(milliseconds: 900), () {
      if (!_isDisposed && _pose == AcadexAssistantPose.magic) {
        _magicSparkleProgress = 1.0;
        notifyListeners();
        onSparklePeak?.call();
      }
    });

    _actionTimer = Timer(totalDuration, () {
      peakTimer.cancel();
      if (!_isDisposed) {
        _magicSparkleProgress = 0.0;
        _pose = AcadexAssistantPose.idle;
        _expression = AcadexAssistantExpression.friendly;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Plays horizontal wiping/clearing action (useful for erasing cards or time board).
  void playWipe({
    Duration duration = const Duration(milliseconds: 1800),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.wipe;
    _expression = AcadexAssistantExpression.focused;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _pose = AcadexAssistantPose.idle;
        _expression = AcadexAssistantExpression.friendly;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Plays focused writing action with rhythmic pen-stroke oscillation.
  void playWrite({
    Duration duration = const Duration(milliseconds: 2200),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.write;
    _expression = AcadexAssistantExpression.focused;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _pose = AcadexAssistantPose.idle;
        _expression = AcadexAssistantExpression.friendly;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Smoothly transitions the assistant to fully appeared / visible.
  void playAppear({
    Duration duration = const Duration(milliseconds: 600),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _visibility = 1.0;
    _pose = AcadexAssistantPose.appear;
    _expression = AcadexAssistantExpression.friendly;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _pose = AcadexAssistantPose.idle;
        _poseProgress = 0.0;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Smoothly transitions the assistant to descend/disappear.
  void playDisappear({
    Duration duration = const Duration(milliseconds: 600),
    VoidCallback? onComplete,
  }) {
    _cancelActionTimer();
    _isActionRunning = true;
    _pose = AcadexAssistantPose.disappear;
    _expression = AcadexAssistantExpression.farewell;
    _poseProgress = 0.0;
    notifyListeners();

    _actionTimer = Timer(duration, () {
      if (!_isDisposed) {
        _visibility = 0.0;
        _pose = AcadexAssistantPose.idle;
        _isActionRunning = false;
        notifyListeners();
        onComplete?.call();
      }
    });
  }

  /// Sets visibility directly (0.0 to 1.0).
  void setVisibility(double val) {
    final clamped = val.clamp(0.0, 1.0);
    if (_visibility != clamped) {
      _visibility = clamped;
      notifyListeners();
    }
  }

  /// Resets to calm idle state with friendly expression.
  void resetToIdle() {
    _cancelActionTimer();
    _pose = AcadexAssistantPose.idle;
    _expression = AcadexAssistantExpression.friendly;
    _gazeDirection = Offset.zero;
    _poseProgress = 0.0;
    _visibility = 1.0;
    _magicSparkleProgress = 0.0;
    _stylusTarget = null;
    _isActionRunning = false;
    notifyListeners();
  }

  bool _isDisposed = false;

  void _cancelActionTimer() {
    _actionTimer?.cancel();
    _actionTimer = null;
    _isActionRunning = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelActionTimer();
    super.dispose();
  }
}
