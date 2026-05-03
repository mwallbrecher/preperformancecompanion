import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../breathing_patterns.dart';

/// 4-7-8 breathing orb with drifting shimmer particles during the 7-second
/// hold phase — keeps the eye engaged without being distracting.
///
/// Takes [wavePhase] (0→2π, from a looping AnimationController in the screen)
/// to animate the shimmer smoothly regardless of the phase timing.
class OrbPainter extends CustomPainter {
  final BreathingAction action;
  final double phaseProgress;
  final double wavePhase;
  final Color primaryColor;
  final Color accentColor;

  const OrbPainter({
    required this.action,
    required this.phaseProgress,
    required this.wavePhase,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.36;

    final t = _easeInOut(phaseProgress);
    final double scale;

    switch (action) {
      case BreathingAction.inhale:
        scale = _lerp(0.35, 1.0, t);
      case BreathingAction.exhale:
        scale = _lerp(1.0, 0.35, t);
      case BreathingAction.hold:
        scale = 1.0;
      case BreathingAction.holdEmpty:
        scale = 0.35;
    }

    final radius = maxRadius * scale;

    // Progress ring — thin circle around the orb showing phase timing
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accentColor.withAlpha(60);
    canvas.drawCircle(center, maxRadius * 1.15, ringPaint);

    final ringArcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withAlpha(200);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius * 1.15),
      -pi / 2,
      2 * pi * phaseProgress,
      false,
      ringArcPaint,
    );

    // Halo
    final haloPaint = Paint()
      ..color = primaryColor.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, radius * 1.3, haloPaint);

    // Main orb
    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: [
          Color.lerp(primaryColor, Colors.white, 0.45)!,
          primaryColor,
          accentColor,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orbPaint);

    // Shimmer particles — only visible during hold, fade in/out smoothly
    final shimmerAlpha = switch (action) {
      BreathingAction.hold => _fadeInOut(phaseProgress),
      _ => 0.0,
    };

    if (shimmerAlpha > 0.01) {
      _drawShimmer(canvas, center, radius, shimmerAlpha);
    }

    // Inner highlight
    final highlightPaint = Paint()..color = Colors.white.withAlpha(70);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.3),
      radius * 0.1,
      highlightPaint,
    );
  }

  void _drawShimmer(Canvas canvas, Offset center, double orbRadius, double alpha) {
    // 6 particles drifting in a slow circular pattern inside the orb
    const particleCount = 6;
    for (int i = 0; i < particleCount; i++) {
      final phaseOffset = (i / particleCount) * 2 * pi;
      final angle = wavePhase + phaseOffset;
      // Each particle orbits at a slightly different radius
      final orbitRadius = orbRadius * (0.35 + 0.2 * sin(wavePhase * 0.5 + i));
      final pos = Offset(
        center.dx + orbitRadius * cos(angle),
        center.dy + orbitRadius * sin(angle * 1.1),
      );
      final particlePaint = Paint()
        ..color = Colors.white.withAlpha((alpha * 150).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, orbRadius * 0.045, particlePaint);
    }
  }

  /// Smooth fade-in / sustain / fade-out over the phase duration
  double _fadeInOut(double t) {
    if (t < 0.2) return t / 0.2;
    if (t > 0.8) return (1 - t) / 0.2;
    return 1.0;
  }

  double _easeInOut(double x) {
    final t = x.clamp(0.0, 1.0);
    return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
  }

  double _lerp(double a, double b, double t) => lerpDouble(a, b, t)!;

  @override
  bool shouldRepaint(OrbPainter old) =>
      old.phaseProgress != phaseProgress ||
      old.action != action ||
      old.wavePhase != wavePhase;
}
