import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'debug/debug_service.dart';
import 'shared/theme/app_theme_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Init debug session + theme mode
  DebugService.instance.startSession('unset');
  await AppThemeMode.instance.load();

  runApp(const PrePerformanceApp());
}
