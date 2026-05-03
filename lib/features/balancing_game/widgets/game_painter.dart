import 'package:flutter/material.dart';
import '../maze_config.dart';

class GamePainter extends CustomPainter {
  final Offset ballPos;
  final List<WallSegment> walls;
  final Rect goalRect;
  final double ballRadius;
  final double wallThickness;

  const GamePainter({
    required this.ballPos,
    required this.walls,
    required this.goalRect,
    required this.ballRadius,
    required this.wallThickness,
  });

  // ── Wood palette ──────────────────────────────────────────────────────────
  static const _floor = Color(0xFFEDE0C4);      // warm cream — corridor floor
  static const _wallTop = Color(0xFFCBB48C);    // wall top face
  static const _wallShadow = Color(0xFF9A7C58); // wall SE face (3-D shadow)
  static const _outerBorder = Color(0xFF7A6040);// thick outer frame
  static const _goalFill = Color(0xFFB8DEBC);   // goal cell tint
  static const _goalDot = Color(0xFF5A9E68);    // goal dot marker

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas);
    _drawGoalCell(canvas);
    _drawWalls(canvas);
    _drawBall(canvas);
  }

  void _drawFloor(Canvas canvas) {
    // Derive maze bounds from outer walls
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final w in walls.where((w) => w.isOuter)) {
      if (w.a.dx < minX) minX = w.a.dx;
      if (w.b.dx < minX) minX = w.b.dx;
      if (w.a.dy < minY) minY = w.a.dy;
      if (w.b.dy < minY) minY = w.b.dy;
      if (w.a.dx > maxX) maxX = w.a.dx;
      if (w.b.dx > maxX) maxX = w.b.dx;
      if (w.a.dy > maxY) maxY = w.a.dy;
      if (w.b.dy > maxY) maxY = w.b.dy;
    }
    if (minX == double.infinity) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(minX, minY, maxX, maxY),
        Radius.circular(wallThickness * 0.8),
      ),
      Paint()..color = _floor,
    );
  }

  void _drawGoalCell(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          goalRect.deflate(wallThickness * 0.2), const Radius.circular(4)),
      Paint()..color = _goalFill,
    );
    canvas.drawCircle(
        goalRect.center, wallThickness * 0.65, Paint()..color = _goalDot);
  }

  void _drawWalls(Canvas canvas) {
    final t = wallThickness;
    for (final wall in walls) {
      final thick = wall.isOuter ? t * 1.6 : t;

      // 3-D raised effect: shadow drawn first at SE offset
      if (!wall.isOuter) {
        _drawSegmentRect(canvas, wall, thick, _wallShadow, dx: 1.4, dy: 1.4);
      }

      _drawSegmentRect(
          canvas, wall, thick, wall.isOuter ? _outerBorder : _wallTop);
    }
  }

  void _drawSegmentRect(
    Canvas canvas,
    WallSegment wall,
    double thick,
    Color color, {
    double dx = 0,
    double dy = 0,
  }) {
    final half = thick / 2;
    final rect = Rect.fromLTRB(
      wall.a.dx - half + dx,
      wall.a.dy - half + dy,
      wall.b.dx + half + dx,
      wall.b.dy + half + dy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(half * 0.5)),
      Paint()..color = color,
    );
  }

  void _drawBall(Canvas canvas) {
    final r = ballRadius;

    // Drop shadow
    canvas.drawCircle(
      ballPos + Offset(r * 0.25, r * 0.38),
      r * 0.88,
      Paint()
        ..color = Colors.black.withAlpha(45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.55),
    );

    // Warm orange ball — matches reference image
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.45),
      colors: const [
        Color(0xFFFFD49A), // warm highlight
        Color(0xFFF5862A), // main orange
        Color(0xFFAA4A08), // deep shadow
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawCircle(
      ballPos,
      r,
      Paint()
        ..shader =
            gradient.createShader(Rect.fromCircle(center: ballPos, radius: r)),
    );
  }

  @override
  bool shouldRepaint(GamePainter old) => old.ballPos != ballPos;
}
