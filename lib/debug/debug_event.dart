class DebugEvent {
  final String sessionId;
  final DateTime timestamp;
  final String screen;
  final String eventType;
  final String elementId;
  final int elapsedMs;

  const DebugEvent({
    required this.sessionId,
    required this.timestamp,
    required this.screen,
    required this.eventType,
    required this.elementId,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'timestamp': timestamp.toIso8601String(),
        'screen': screen,
        'eventType': eventType,
        'elementId': elementId,
        'elapsedMs': elapsedMs,
      };

  List<dynamic> toCsvRow() => [
        sessionId,
        timestamp.toIso8601String(),
        screen,
        eventType,
        elementId,
        elapsedMs,
      ];

  @override
  String toString() =>
      '[$screen] $eventType / $elementId @ ${elapsedMs}ms';
}
