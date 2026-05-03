import 'dart:math';
import 'package:flutter/material.dart';
import '../breathing_patterns.dart';

/// Box Breathing — a rounded square with a glowing dot tracing its perimeter.
///
/// Phase 0 (inhale):     top side,    left → right
/// Phase 1 (hold):       right side,  top → bottom
/// Phase 2 (exhale):     bottom side, right → left
/// Phase 3 (hold empty): left side,   bottom → top
///
/// The traced sides glow with accent colour, giving a visible record of the
/// current cycle. Trail resets on each new cycle.
class BreathingBoxPainter extends CustomPainter {
  final int phaseIndex;
  final double phaseProgress;
  final BreathingAction action;
  final Color primaryColor;
  final Color accentColor;

  const BreathingBoxPainter({
    required this.phaseIndex,
    required this.phaseProgress,
    required this.action,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxSize = min(size.width, size.height) * 0.66;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;

    const cornerRadius = 18.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(cornerRadius),
    );

    // Base outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = primaryColor.withAlpha(90);
    canvas.drawRRect(rrect, outlinePaint);

    // Highlighted side for the CURRENT phase — eases across as dot moves
    final t = _easeInOut(phaseProgress);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accentColor;

    _drawPhaseSide(canvas, phaseIndex, t, left, top, right, bottom, cornerRadius, activePaint);

    // Faded trail of already-completed sides in this cycle
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withAlpha(120);
    for (int i = 0; i < phaseIndex; i++) {
      _drawPhaseSide(canvas, i, 1.0, left, top, right, bottom, cornerRadius, trailPaint);
    }

    // The glowing dot
    final dotPos = _dotPosition(phaseIndex, t, left, top, right, bottom, cornerRadius);

    final glowPaint = Paint()
      ..color = accentColor.withAlpha(140)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(dotPos, 16, glowPaint);

    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, accentColor],
      ).createShader(Rect.fromCircle(center: dotPos, radius: 8));
    canvas.drawCircle(dotPos, 8, dotPaint);

    // Centre label helper — small action-colour dot in the middle
    // gives a subtle focal anchor
    final centerDotPaint = Paint()
      ..color = _actionColor(action).withAlpha(50);
    canvas.drawCircle(
      Offset((left + right) / 2, (top + bottom) / 2),
      6,
      centerDotPaint,
    );
  }

  /// Draw the side for [phase] filled by [t] (0→1).
  void _drawPhaseSide(
    Canvas canvas,
    int phase,
    double t,
    double l,
    double tp,
    double r,
    double b,
    double cr,
    Paint paint,
  ) {
    // Each side runs between its rounded-corner endpoints
    final path = Path();
    switch (phase) {
      case 0: // top: left→right
        path.moveTo(l + cr, tp);
        path.lineTo(l + cr + (r - l - 2 * cr) * t, tp);
      case 1: // right: top→bottom
        path.moveTo(r, tp + cr);
        path.lineTo(r, tp + cr + (b - tp - 2 * cr) * t);
      case 2: // bottom: right→left
        path.moveTo(r - cr, b);
        path.lineTo(r - cr - (r - l - 2 * cr) * t, b);
      case 3: // left: bottom→top
        path.moveTo(l, b - cr);
        path.lineTo(l, b - cr - (b - tp - 2 * cr) * t);
    }
    canvas.drawPath(path, paint);
  }

  Offset _dotPosition(
    int phase,
    double t,
    double l,
    double tp,
    double r,
    double b,
    double cr,
  ) {
    switch (phase) {
      case 0:
        return Offset(l + cr + (r - l - 2 * cr) * t, tp);
      case 1:
        return Offset(r, tp + cr + (b - tp - 2 * cr) * t);
      case 2:
        return Offset(r - cr - (r - l - 2 * cr) * t, b);
      case 3:
        return Offset(l, b - cr - (b - tp - 2 * cr) * t);
      default:
        return Offset(l, tp);
    }
  }

  Color _actionColor(BreathingAction a) {
    switch (a) {
      case BreathingAction.inhale:
      case BreathingAction.exhale:
        return accentColor;
      case BreathingAction.hold:
      case BreathingAction.holdEmpty:
        return primaryColor;
    }
  }

  double _easeInOut(double x) {
    final t = x.clamp(0.0, 1.0);
    return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
  }

  @override
  bool shouldRepaint(BreathingBoxPainter old) =>
      old.phaseProgress != phaseProgress ||
      old.phaseIndex != phaseIndex ||
      old.action != action;
}
