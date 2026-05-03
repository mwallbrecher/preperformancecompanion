import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme mode toggle used for UX research sessions.
///
/// When [lowFi] is true, the app renders a greybox / wireframe look so
/// participants focus on information architecture and flow rather than
/// visual design. Persists across launches via SharedPreferences.
class AppThemeMode extends ChangeNotifier {
  AppThemeMode._();
  static final AppThemeMode instance = AppThemeMode._();

  static const _prefsKey = 'app_theme_low_fi';

  bool _lowFi = false;
  bool get lowFi => _lowFi;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lowFi = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  Future<void> setLowFi(bool value) async {
    if (_lowFi == value) return;
    _lowFi = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> toggle() => setLowFi(!_lowFi);
}
