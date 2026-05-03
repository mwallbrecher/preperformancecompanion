import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'breathing_patterns.dart';

/// Drives phase progression for any [BreathingPattern].
///
/// Loops through the pattern's phases for [sessionDuration]; exposes current
/// phase, progress within the phase (0→1 with linear time — painters apply
/// easing themselves), and overall session progress.
class BreathingNotifier extends ChangeNotifier {
  final BreathingPattern pattern;
  final Duration sessionDuration;

  int _currentPhaseIndex = 0;
  Duration _phaseElapsed = Duration.zero;
  Duration _totalElapsed = Duration.zero;
  int _completedCycles = 0;

  bool _isRunning = false;
  bool _isComplete = false;

  // ── Touch mode state ──────────────────────────────────────────────────────
  bool _touchMode = false;
  bool _isTouching = false;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  BreathingNotifier({
    required this.pattern,
    this.sessionDuration = const Duration(minutes: 2),
  });

  // ── Getters ────────────────────────────────────────────────────────────────
  BreathingPhase get currentPhase => pattern.phases[_currentPhaseIndex];
  int get currentPhaseIndex => _currentPhaseIndex;

  /// 0→1 linear progress within the current phase.
  double get phaseProgress {
    final ms = currentPhase.duration.inMilliseconds;
    if (ms == 0) return 0;
    return (_phaseElapsed.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  /// 0→1 progress of the whole session.
  double get overallProgress {
    final ms = sessionDuration.inMilliseconds;
    if (ms == 0) return 0;
    return (_totalElapsed.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  /// Seconds remaining in the current phase, rounded up so the countdown
  /// reaches 1 before the phase actually ends.
  int get phaseSecondsRemaining {
    final remainingMs = currentPhase.duration.inMilliseconds -
        _phaseElapsed.inMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  int get completedCycles => _completedCycles;
  bool get isRunning => _isRunning;
  bool get isComplete => _isComplete;
  Duration get totalElapsed => _totalElapsed;

  // ── Touch mode ────────────────────────────────────────────────────────────
  bool get touchMode => _touchMode;
  bool get isTouching => _isTouching;

  /// Whether the current touch state matches the expected action.
  /// Exhale/hold → finger down. Inhale/holdEmpty → finger up.
  bool get isInSync {
    if (!_touchMode) return true;
    switch (currentPhase.action) {
      case BreathingAction.exhale:
      case BreathingAction.hold:
        return _isTouching;
      case BreathingAction.inhale:
      case BreathingAction.holdEmpty:
        return !_isTouching;
    }
  }

  void setTouchMode(bool enabled) {
    if (_touchMode == enabled) return;
    _touchMode = enabled;
    if (!enabled) _isTouching = false;
    notifyListeners();
  }

  void setTouching(bool touching) {
    if (_isTouching == touching) return;
    _isTouching = touching;
    notifyListeners();
  }

  // ── Control ────────────────────────────────────────────────────────────────
  void start(TickerProvider vsync) {
    if (_isRunning) return;
    _isRunning = true;
    _isComplete = false;
    _currentPhaseIndex = 0;
    _phaseElapsed = Duration.zero;
    _totalElapsed = Duration.zero;
    _completedCycles = 0;
    _lastTick = Duration.zero;

    _ticker = vsync.createTicker(_onTick)..start();
    notifyListeners();
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    _ticker?.stop();
    notifyListeners();
  }

  // ── Tick ──────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!_isRunning) return;
    final dt = elapsed - _lastTick;
    _lastTick = elapsed;
    // Skip first frame / stutter-guard
    if (dt <= Duration.zero || dt > const Duration(milliseconds: 100)) {
      return;
    }

    // In touch mode, time only advances while the user is doing the
    // correct action for the current phase.
    if (_touchMode && !isInSync) {
      notifyListeners(); // allow UI hint to stay fresh
      return;
    }

    _phaseElapsed += dt;
    _totalElapsed += dt;

    // Advance phases — while handles the rare case of a very long dt
    while (_phaseElapsed >= currentPhase.duration) {
      _phaseElapsed -= currentPhase.duration;
      _currentPhaseIndex++;
      if (_currentPhaseIndex >= pattern.phases.length) {
        _currentPhaseIndex = 0;
        _completedCycles++;
      }
    }

    // End session when time is up
    if (_totalElapsed >= sessionDuration) {
      _totalElapsed = sessionDuration;
      _isRunning = false;
      _isComplete = true;
      _ticker?.stop();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
