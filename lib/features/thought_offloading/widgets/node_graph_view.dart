import 'package:flutter/material.dart';
import '../models/thought_node.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

class NodeGraphView extends StatelessWidget {
  final List<ThoughtNode> nodes;

  const NodeGraphView({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NodePainter(nodes: nodes),
      size: Size.infinite,
    );
  }
}

class _NodePainter extends CustomPainter {
  final List<ThoughtNode> nodes;

  const _NodePainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    final edgePaint = Paint()
      ..color = AppColors.nodeEdge.withAlpha(100)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      if (node.connectedToId == null) continue;
      final parent = nodes.cast<ThoughtNode?>().firstWhere(
            (n) => n?.id == node.connectedToId,
            orElse: () => null,
          );
      if (parent == null) continue;
      canvas.drawLine(parent.position, node.position, edgePaint);
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      // Glow / shadow
      final glowPaint = Paint()
        ..color = node.color.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(node.position, node.radius + 6, glowPaint);

      // Fill
      final fillPaint = Paint()
        ..color = node.color.withAlpha(160)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node.position, node.radius, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = node.color.withAlpha(220)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(node.position, node.radius, borderPaint);

      // Text label
      _drawText(canvas, node);
    }
  }

  void _drawText(Canvas canvas, ThoughtNode node) {
    final maxChars = node.radius > 36 ? 18 : 12;
    final display = node.text.length > maxChars
        ? '${node.text.substring(0, maxChars - 1)}…'
        : node.text;

    final tp = TextPainter(
      text: TextSpan(text: display, style: AppTextStyles.nodeLabel),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: node.radius * 1.6);

    tp.paint(
      canvas,
      node.position - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_NodePainter old) => old.nodes != nodes || old.nodes.length != nodes.length;
}
