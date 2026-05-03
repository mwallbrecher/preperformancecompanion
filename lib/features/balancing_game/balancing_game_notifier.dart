import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'maze_config.dart';

class BalancingGameNotifier extends ChangeNotifier {
  static const int maxSeconds = 60;
  static const double _gravity = 900.0;       // px/s²
  static const double _maxSpeed = 320.0;       // px/s cap
  static const double _filterAlpha = 0.14;     // low-pass blend (applied in tick)
  static const double _frictionRetain = 0.70;  // speed × pow(0.70, dt) per second
  static const double _restitution = 0.18;     // wall bounciness (0=dead stop, 1=elastic)

  final MazeConfig _maze = MazeConfig.generate();

  // ── Layout (set once from LayoutBuilder) ──────────────────────────────────
  List<WallSegment> _walls = [];
  Rect _goalRect = Rect.zero;
  Offset _startPos = Offset.zero;
  double _ballRadius = 12.0;
  double _wallThickness = 8.0;
  bool _layoutReady = false;

  // ── Physics state ──────────────────────────────────────────────────────────
  Offset _ballPos = Offset.zero;
  Offset _velocity = Offset.zero;
  double _rawX = 0, _rawY = 0;
  double _calRawX = 0, _calRawY = 0; // calibration baseline captured at start
  bool _calibrated = false;
  double _smoothX = 0, _smoothY = 0;
  Duration _lastTick = Duration.zero;

  // ── Session state ──────────────────────────────────────────────────────────
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _reachedGoal = false;

  StreamSubscription<AccelerometerEvent>? _sensorSub;
  Ticker? _ticker;
  Timer? _countdownTimer;

  // ── Public getters ─────────────────────────────────────────────────────────
  Offset get ballPos => _ballPos;
  List<WallSegment> get walls => _walls;
  Rect get goalRect => _goalRect;
  double get ballRadius => _ballRadius;
  double get wallThickness => _wallThickness;
  bool get layoutReady => _layoutReady;
  int get mazeCols => _maze.cols;
  int get mazeRows => _maze.rows;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  bool get reachedGoal => _reachedGoal;
  double get timeProgress => _elapsedSeconds / maxSeconds;

  // ── Layout setup ──────────────────────────────────────────────────────────
  void setLayout({
    required double x0,
    required double y0,
    required double cellW,
    required double cellH,
  }) {
    _wallThickness = (min(cellW, cellH) * 0.13).clamp(5.0, 10.0);
    _ballRadius = (min(cellW, cellH) * 0.16).clamp(7.0, 12.0);
    _walls = _maze.buildSegments(x0, y0, cellW, cellH);
    _goalRect = _maze.goalRect(x0, y0, cellW, cellH);
    _startPos = _maze.startCenter(x0, y0, cellW, cellH);
    _ballPos = _startPos;
    _layoutReady = true;
    notifyListeners();
  }

  // ── Start / Stop ───────────────────────────────────────────────────────────
  void start(TickerProvider vsync) {
    if (_isRunning || !_layoutReady) return;
    _isRunning = true;
    _elapsedSeconds = 0;
    _ballPos = _startPos;
    _velocity = Offset.zero;
    _smoothX = 0;
    _smoothY = 0;
    _reachedGoal = false;
    _lastTick = Duration.zero;
    _calibrated = false;

    // Ultra-light callback: store raw values; capture the very first reading
    // as the neutral baseline so the current phone angle = "flat" for the game.
    _sensorSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      _rawX = e.x;
      _rawY = e.y;
      if (!_calibrated) {
        _calRawX = e.x;
        _calRawY = e.y;
        _calibrated = true;
      }
    });

    _ticker = vsync.createTicker(_onTick)..start();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (_elapsedSeconds >= maxSeconds) stop();
      notifyListeners();
    });
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    _ticker?.stop();
    _sensorSub?.cancel();
    _countdownTimer?.cancel();
    notifyListeners();
  }

  // ── Physics tick (~60 fps) ─────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!_isRunning) return;
    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.1) return; // skip first frame and any stutter

    // Low-pass filter on calibrated delta — applied here, NOT in sensor callback
    // Subtract the baseline captured at start so the initial phone angle = neutral
    _smoothX += _filterAlpha * (-(_rawX - _calRawX) - _smoothX);
    _smoothY += _filterAlpha * ((_rawY - _calRawY) - _smoothY);

    // Gravity from tilt
    _velocity = Offset(
      _velocity.dx + _smoothX * _gravity * dt,
      _velocity.dy + _smoothY * _gravity * dt,
    );

    // Speed cap
    final speed = _velocity.distance;
    if (speed > _maxSpeed) {
      _velocity = _velocity * (_maxSpeed / speed);
    }

    // Exponential friction (wood surface feel)
    final friction = pow(_frictionRetain, dt).toDouble();
    _velocity = _velocity * friction;

    // Integrate position
    var newPos = _ballPos + _velocity * dt;

    // 3-pass collision resolution for stability near corners
    for (int i = 0; i < 3; i++) {
      newPos = _resolveCollisions(newPos);
    }
    _ballPos = newPos;

    // Goal check
    if (!_reachedGoal && _goalRect.contains(_ballPos)) {
      _reachedGoal = true;
      stop();
      return;
    }

    notifyListeners();
  }

  Offset _resolveCollisions(Offset pos) {
    // effectiveRadius accounts for visual wall thickness
    final effectiveR = _ballRadius + _wallThickness * 0.5;
    var p = pos;

    for (final wall in _walls) {
      final closest = wall.closestPoint(p);
      final delta = p - closest;
      final dist = delta.distance;
      if (dist < effectiveR && dist > 0) {
        final normal = delta / dist;
        // Push ball outside wall
        p = closest + normal * effectiveR;
        // Reflect and dampen the normal velocity component
        final vDotN = _velocity.dx * normal.dx + _velocity.dy * normal.dy;
        if (vDotN < 0) {
          _velocity = Offset(
            _velocity.dx - (1.0 + _restitution) * vDotN * normal.dx,
            _velocity.dy - (1.0 + _restitution) * vDotN * normal.dy,
          );
        }
      }
    }
    return p;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _sensorSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
