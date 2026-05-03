import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'debug_event.dart';

class DebugService extends ChangeNotifier {
  DebugService._();
  static final DebugService instance = DebugService._();

  String _sessionId = 'unset';
  DateTime? _sessionStart;
  String? _lastFeature;
  final List<DebugEvent> _events = [];

  // ── Public state ──────────────────────────────────────────────────────────

  String get sessionId => _sessionId;
  DateTime? get sessionStart => _sessionStart;
  String? get lastFeature => _lastFeature;
  List<DebugEvent> get events => List.unmodifiable(_events);
  int get eventCount => _events.length;

  Duration get sessionDuration {
    if (_sessionStart == null) return Duration.zero;
    return DateTime.now().difference(_sessionStart!);
  }

  // ── API ───────────────────────────────────────────────────────────────────

  void startSession(String id) {
    _sessionId = id.trim().isEmpty ? 'unset' : id.trim();
    _sessionStart = DateTime.now();
    _events.clear();
    notifyListeners();
    _log('session_started', 'session', 'session_start', 'session_init');
  }

  void logEvent({
    required String screen,
    required String eventType,
    required String elementId,
  }) {
    final elapsed = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inMilliseconds
        : 0;
    final event = DebugEvent(
      sessionId: _sessionId,
      timestamp: DateTime.now(),
      screen: screen,
      eventType: eventType,
      elementId: elementId,
      elapsedMs: elapsed,
    );
    _events.add(event);
    if (eventType == 'feature_select') _lastFeature = elementId;
    debugPrint('[Debug] $event');
    notifyListeners();
  }

  void clearSession() {
    _events.clear();
    notifyListeners();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  String exportJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_events.map((e) => e.toJson()).toList());
  }

  String exportMarkdown() {
    final buf = StringBuffer()
      ..writeln('# Debug Session — $_sessionId')
      ..writeln()
      ..writeln('- **Started:** ${_sessionStart?.toIso8601String() ?? '—'}')
      ..writeln('- **Events:** ${_events.length}')
      ..writeln('- **Duration:** ${sessionDuration.inSeconds}s')
      ..writeln()
      ..writeln('| Elapsed | Screen | Type | Element |')
      ..writeln('|---|---|---|---|');
    for (final e in _events) {
      buf.writeln(
          '| ${e.elapsedMs}ms | ${e.screen} | ${e.eventType} | ${e.elementId} |');
    }
    return buf.toString();
  }

  String exportTxt() {
    final buf = StringBuffer()
      ..writeln('Debug Session: $_sessionId')
      ..writeln('Started: ${_sessionStart?.toIso8601String() ?? '—'}')
      ..writeln('Events:  ${_events.length}')
      ..writeln('Duration: ${sessionDuration.inSeconds}s')
      ..writeln('-' * 60);
    for (final e in _events) {
      buf.writeln(
          '${e.elapsedMs.toString().padLeft(7)}ms  ${e.screen.padRight(22)} ${e.eventType.padRight(16)} ${e.elementId}');
    }
    return buf.toString();
  }

  String exportCsv() {
    final rows = <List<dynamic>>[
      ['sessionId', 'timestamp', 'screen', 'eventType', 'elementId', 'elapsedMs'],
      ..._events.map((e) => e.toCsvRow()),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<String> saveJsonFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${_sessionId}_$ts.json');
    await file.writeAsString(exportJson());
    return file.path;
  }

  Future<String> saveCsvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${_sessionId}_$ts.csv');
    await file.writeAsString(exportCsv());
    return file.path;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _log(String screen, String elementId, String eventType, String element) {
    logEvent(screen: screen, eventType: eventType, elementId: elementId);
  }
}
