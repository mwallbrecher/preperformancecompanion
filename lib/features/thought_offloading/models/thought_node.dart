import 'package:flutter/material.dart';

class ThoughtNode {
  final String id;
  final String text;
  Offset position;
  final double radius;
  final Color color;
  final String? connectedToId;

  ThoughtNode({
    required this.id,
    required this.text,
    required this.position,
    required this.radius,
    required this.color,
    this.connectedToId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'posX': position.dx,
        'posY': position.dy,
        'radius': radius,
        'colorValue': color.toARGB32(),
        'connectedToId': connectedToId,
      };

  factory ThoughtNode.fromJson(Map<String, dynamic> j) => ThoughtNode(
        id: j['id'] as String,
        text: j['text'] as String,
        position: Offset(
          (j['posX'] as num).toDouble(),
          (j['posY'] as num).toDouble(),
        ),
        radius: (j['radius'] as num).toDouble(),
        color: Color(j['colorValue'] as int),
        connectedToId: j['connectedToId'] as String?,
      );
}
