import 'dart:math';
import 'package:flutter/material.dart';

/// Axis-aligned wall segment. Physics models walls as zero-thickness lines;
/// collision radius = ballRadius + wallThickness/2 for visual accuracy.
class WallSegment {
  final Offset a, b;
  final bool isHorizontal;
  final bool isOuter;

  const WallSegment(this.a, this.b,
      {required this.isHorizontal, this.isOuter = false});

  /// Closest point on this segment to [p].
  Offset closestPoint(Offset p) {
    if (isHorizontal) {
      return Offset(p.dx.clamp(a.dx, b.dx), a.dy);
    } else {
      return Offset(a.dx, p.dy.clamp(a.dy, b.dy));
    }
  }
}

/// DFS-generated perfect maze — exactly one solution path, every cell reachable.
class MazeConfig {
  final int cols;
  final int rows;

  /// passages[r][c] = bitmask of OPEN directions:
  ///   bit 0 = North, bit 1 = East, bit 2 = South, bit 3 = West
  final List<List<int>> passages;

  const MazeConfig._({
    required this.cols,
    required this.rows,
    required this.passages,
  });

  factory MazeConfig.generate({int cols = 8, int rows = 15, int? seed}) {
    final rng = seed != null ? Random(seed) : Random();
    final passages = List.generate(rows, (_) => List.filled(cols, 0));
    final visited = List.generate(rows, (_) => List.filled(cols, false));

    const dr = [-1, 0, 1, 0]; // N E S W
    const dc = [0, 1, 0, -1];
    const opp = [2, 3, 0, 1]; // opposite direction index

    void dfs(int r, int c) {
      visited[r][c] = true;
      final dirs = [0, 1, 2, 3]..shuffle(rng);
      for (final d in dirs) {
        final nr = r + dr[d], nc = c + dc[d];
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && !visited[nr][nc]) {
          passages[r][c] |= 1 << d;
          passages[nr][nc] |= 1 << opp[d];
          dfs(nr, nc);
        }
      }
    }

    dfs(0, 0);
    return MazeConfig._(cols: cols, rows: rows, passages: passages);
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Offset startCenter(double x0, double y0, double cW, double cH) =>
      Offset(x0 + 0.5 * cW, y0 + 0.5 * cH);

  Rect goalRect(double x0, double y0, double cW, double cH) =>
      Rect.fromLTWH(x0 + (cols - 1) * cW, y0 + (rows - 1) * cH, cW, cH);

  /// Build wall segment list for physics + rendering.
  List<WallSegment> buildSegments(double x0, double y0, double cW, double cH) {
    final segs = <WallSegment>[];
    final x1 = x0 + cols * cW, y1 = y0 + rows * cH;

    // Outer border
    segs.add(WallSegment(Offset(x0, y0), Offset(x1, y0),
        isHorizontal: true, isOuter: true));
    segs.add(WallSegment(Offset(x0, y1), Offset(x1, y1),
        isHorizontal: true, isOuter: true));
    segs.add(WallSegment(Offset(x0, y0), Offset(x0, y1),
        isHorizontal: false, isOuter: true));
    segs.add(WallSegment(Offset(x1, y0), Offset(x1, y1),
        isHorizontal: false, isOuter: true));

    // Interior walls — each unique wall emitted once
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = x0 + c * cW, cy = y0 + r * cH;

        // East wall between (r,c) and (r,c+1)
        if (c < cols - 1 && (passages[r][c] & (1 << 1)) == 0) {
          segs.add(WallSegment(
            Offset(cx + cW, cy),
            Offset(cx + cW, cy + cH),
            isHorizontal: false,
          ));
        }

        // South wall between (r,c) and (r+1,c)
        if (r < rows - 1 && (passages[r][c] & (1 << 2)) == 0) {
          segs.add(WallSegment(
            Offset(cx, cy + cH),
            Offset(cx + cW, cy + cH),
            isHorizontal: true,
          ));
        }
      }
    }

    return segs;
  }
}
