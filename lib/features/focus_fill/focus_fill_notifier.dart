import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

enum FillState { idle, running, complete }

class FocusFillNotifier extends ChangeNotifier {
  FillState _state = FillState.idle;
  Duration _selectedDuration = const Duration(minutes: 1);
  Duration _elapsed = Duration.zero;
  Ticker? _ticker;

  FillState get state => _state;
  Duration get selectedDuration => _selectedDuration;
  Duration get elapsed => _elapsed;

  double get progress {
    if (_selectedDuration.inMilliseconds == 0) return 0;
    return (_elapsed.inMilliseconds / _selectedDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void setDuration(Duration d) {
    _selectedDuration = d;
    notifyListeners();
  }

  void start(TickerProvider vsync) {
    if (_state == FillState.running) return;
    _elapsed = Duration.zero;
    _state = FillState.running;
    _ticker = vsync.createTicker(_onTick)..start();
    notifyListeners();
  }

  void reset() {
    _ticker?.stop();
    _elapsed = Duration.zero;
    _state = FillState.idle;
    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    if (_elapsed >= _selectedDuration) {
      _elapsed = _selectedDuration;
      _ticker?.stop();
      _state = FillState.complete;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    super.dispose();
  }
}
