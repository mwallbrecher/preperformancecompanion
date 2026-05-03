import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../breathing_patterns.dart';

/// Soft breathing orb with a warm/cool colour shift tied to inhale vs exhale.
/// Fast expansion (inhale, 2s) → slow contraction (exhale, 4s) teaches the
/// asymmetric rhythm without words.
class PursedLipPainter extends CustomPainter {
  final BreathingAction action;
  final double phaseProgress; // 0→1 linear
  final Color coolColor;      // inhale colour (mint)
  final Color warmColor;      // exhale colour (peach)

  const PursedLipPainter({
    required this.action,
    required this.phaseProgress,
    required this.coolColor,
    required this.warmColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.35;

    final t = _easeInOut(phaseProgress);
    final double scale;
    final Color color;

    switch (action) {
      case BreathingAction.inhale:
        scale = _lerp(0.35, 1.0, t);
        color = Color.lerp(warmColor, coolColor, t)!;
      case BreathingAction.exhale:
        scale = _lerp(1.0, 0.35, t);
        color = Color.lerp(coolColor, warmColor, t)!;
      case BreathingAction.hold:
        scale = 1.0;
        color = coolColor;
      case BreathingAction.holdEmpty:
        scale = 0.35;
        color = warmColor;
    }

    final radius = maxRadius * scale;

    // Outer soft halo (blurred)
    final haloPaint = Paint()
      ..color = color.withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius * 1.25, haloPaint);

    // Main orb — radial gradient for depth
    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        colors: [
          Color.lerp(color, Colors.white, 0.4)!,
          color,
          color.withAlpha(220),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orbPaint);

    // Inner highlight dot — subtle shimmer
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(80);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.3),
      radius * 0.12,
      highlightPaint,
    );
  }

  double _easeInOut(double x) {
    final t = x.clamp(0.0, 1.0);
    return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
  }

  double _lerp(double a, double b, double t) => lerpDouble(a, b, t)!;

  @override
  bool shouldRepaint(PursedLipPainter old) =>
      old.phaseProgress != phaseProgress || old.action != action;
}
