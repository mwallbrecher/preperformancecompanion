import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/app_theme_mode.dart';
import 'router.dart';

class PrePerformanceApp extends StatelessWidget {
  const PrePerformanceApp({super.key});

  // Perceptual luminance grayscale matrix (ITU-R BT.709).
  static const _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrePerformance Companion',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: onGenerateRoute,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: AppThemeMode.instance,
          builder: (_, _) {
            if (!AppThemeMode.instance.lowFi) return child ?? const SizedBox();
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
              child: child,
            );
          },
        );
      },
    );
  }
}
