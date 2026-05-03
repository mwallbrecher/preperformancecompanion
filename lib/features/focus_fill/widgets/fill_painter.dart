import 'dart:math';
import 'package:flutter/material.dart';

class FillPainter extends CustomPainter {
  final double fillLevel; // 0.0 → 1.0
  final double wavePhase; // 0.0 → 2π

  const FillPainter({
    required this.fillLevel,
    required this.wavePhase,
  });

  // ── Color journey: airy lavender-blue → rich teal-indigo ──────────────────
  static const Color _topStart    = Color(0xFFBFADE0); // soft lavender
  static const Color _topEnd      = Color(0xFF7ABAC0); // calm teal
  static const Color _bottomStart = Color(0xFF9BB5D9); // pale blue
  static const Color _bottomEnd   = Color(0xFF6878C4); // deep indigo

  // A slightly brighter mid-tone for the secondary wave shimmer
  static const Color _shimmerStart = Color(0xFFCCC0EC);
  static const Color _shimmerEnd   = Color(0xFF90CCd0);

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0) return;

    // Interpolated colours based on how full the water is
    final t = fillLevel.clamp(0.0, 1.0);
    final topColor    = Color.lerp(_topStart,     _topEnd,     t)!;
    final bottomColor = Color.lerp(_bottomStart,  _bottomEnd,  t)!;
    final shimmerColor = Color.lerp(_shimmerStart, _shimmerEnd, t)!;

    final baseY = size.height * (1.0 - fillLevel);
    const amplitude = 12.0;
    const wavelength = 220.0;

    // Primary wave with animated gradient fill
    final path1 = _buildWavePath(size, baseY, wavePhase, amplitude, wavelength);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
    final paint1 = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, baseY - amplitude, size.width, size.height - baseY + amplitude),
      );
    canvas.drawPath(path1, paint1);

    // Secondary shimmer wave (offset by π for depth, slightly translucent)
    final path2 = _buildWavePath(
      size,
      baseY + amplitude * 0.4,
      wavePhase + pi,
      amplitude * 0.6,
      wavelength * 1.3,
    );
    final paint2 = Paint()..color = shimmerColor.withAlpha(90);
    canvas.drawPath(path2, paint2);
  }

  Path _buildWavePath(
    Size size,
    double baseY,
    double phase,
    double amplitude,
    double wavelength,
  ) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    const step = 4.0;
    for (double x = 0; x <= size.width; x += step) {
      final y = baseY + amplitude * sin((x / wavelength) * 2 * pi + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(FillPainter old) =>
      old.fillLevel != fillLevel || old.wavePhase != wavePhase;
}
