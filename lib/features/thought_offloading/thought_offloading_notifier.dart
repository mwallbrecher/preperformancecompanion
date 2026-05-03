import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../shared/theme/app_colors.dart';
import 'models/thought_node.dart';

enum RecordingState { idle, initialising, listening, processing, unavailable }

class ThoughtOffloadingNotifier extends ChangeNotifier {
  static const _prefsKey = 'thought_offloading_nodes';

  final _speech = SpeechToText();
  RecordingState _recordingState = RecordingState.idle;
  final List<ThoughtNode> _nodes = [];
  String _interimText = '';
  bool _speechAvailable = false;
  bool _wantListening = false; // true while user wants mic active
  double _screenWidth = 375;
  double _screenHeight = 812;

  static const _nodeColors = [
    AppColors.nodeA,
    AppColors.nodeB,
    AppColors.nodeC,
    AppColors.nodeD,
    AppColors.blobPink,
    AppColors.blobMint,
  ];

  // ── Public getters ────────────────────────────────────────────────────────
  RecordingState get recordingState => _recordingState;
  List<ThoughtNode> get nodes => List.unmodifiable(_nodes);
  String get interimText => _interimText;
  bool get speechAvailable => _speechAvailable;
  bool get isListening => _recordingState == RecordingState.listening;

  // ── Init ──────────────────────────────────────────────────────────────────
  void setScreenSize(double w, double h) {
    _screenWidth = w;
    _screenHeight = h;
  }

  Future<void> initialize() async {
    _recordingState = RecordingState.initialising;
    notifyListeners();

    // Load persisted nodes before showing the screen
    await _loadNodes();

    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    _recordingState =
        _speechAvailable ? RecordingState.idle : RecordingState.unavailable;
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _loadNodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _nodes.clear();
      for (final item in list) {
        _nodes.add(ThoughtNode.fromJson(item as Map<String, dynamic>));
      }
    } catch (e) {
      debugPrint('[ThoughtOffloading] Failed to load nodes: $e');
    }
  }

  Future<void> _saveNodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_nodes.map((n) => n.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (e) {
      debugPrint('[ThoughtOffloading] Failed to save nodes: $e');
    }
  }

  // ── Recording control ─────────────────────────────────────────────────────
  Future<void> startListening() async {
    if (!_speechAvailable || _wantListening) return;
    _wantListening = true;
    await _doListen();
  }

  Future<void> stopListening() async {
    if (!_wantListening) return;
    _wantListening = false;
    _recordingState = RecordingState.processing;
    notifyListeners();
    await _speech.stop();
    _interimText = '';
    _recordingState = RecordingState.idle;
    notifyListeners();
  }

  Future<void> _doListen() async {
    if (!_wantListening || !_speechAvailable) return;
    _recordingState = RecordingState.listening;
    notifyListeners();
    await _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> clearNodes() async {
    _nodes.clear();
    _interimText = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  // ── Speech callbacks ──────────────────────────────────────────────────────
  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _interimText = '';
      _parseAndAddNodes(result.recognizedWords);
      _saveNodes(); // persist immediately after new nodes
      notifyListeners();
      // Auto-restart so the user can keep speaking without re-tapping
      if (_wantListening) {
        Future.delayed(const Duration(milliseconds: 200), _doListen);
      }
    } else {
      _interimText = result.recognizedWords;
      notifyListeners();
    }
  }

  void _onSpeechStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      if (_wantListening) {
        // Engine stopped on its own — restart
        Future.delayed(const Duration(milliseconds: 200), _doListen);
      } else {
        _recordingState = RecordingState.idle;
        _interimText = '';
        notifyListeners();
      }
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('[SpeechToText] error: $error');
    if (_wantListening) {
      // Try restarting after a short back-off
      Future.delayed(const Duration(milliseconds: 500), _doListen);
    } else {
      _recordingState = RecordingState.idle;
      _interimText = '';
      notifyListeners();
    }
  }

  // ── Node parsing ──────────────────────────────────────────────────────────
  void _parseAndAddNodes(String text) {
    if (text.trim().isEmpty) return;

    final chunks = text
        .split(RegExp(r'[.,!?]|(?:\s+(?:and|but|because|so|then|also)\s+)'))
        .map((s) => s.trim())
        .where((s) => s.length >= 2)
        .toList();

    final source = chunks.isEmpty ? [text.trim()] : chunks;
    for (final chunk in source) {
      if (_nodes.length >= 14) break;
      _addNode(chunk);
    }
  }

  void _addNode(String text) {
    final index = _nodes.length;
    final prevId = index > 0 ? _nodes[index - 1].id : null;
    final pos = _computePosition(index);
    final radius = (22.0 + min(text.length * 1.2, 26.0)).clamp(22.0, 48.0);
    final color = _nodeColors[index % _nodeColors.length];

    _nodes.add(ThoughtNode(
      id: 'node_$index',
      text: text,
      position: pos,
      radius: radius,
      color: color,
      connectedToId: prevId,
    ));
  }

  Offset _computePosition(int index) {
    const goldenAngle = 2.399963;
    final cx = _screenWidth * 0.5;
    final cy = _screenHeight * 0.42;
    final maxR = min(_screenWidth, _screenHeight) * 0.32;

    if (index == 0) return Offset(cx, cy);

    final angle = index * goldenAngle;
    final r = maxR * sqrt(index / 14.0) + 50;
    return Offset(
      (cx + r * cos(angle)).clamp(60.0, _screenWidth - 60),
      (cy + r * sin(angle)).clamp(100.0, _screenHeight * 0.75),
    );
  }

  @override
  void dispose() {
    _wantListening = false;
    _speech.cancel();
    super.dispose();
  }
}
