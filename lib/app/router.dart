import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/focus_fill/focus_fill_screen.dart';
import '../features/balancing_game/balancing_game_screen.dart';
import '../features/thought_offloading/thought_offloading_screen.dart';
import '../features/breathing/breathing_selection_screen.dart';
import '../features/breathing/breathing_session_screen.dart';
import '../features/breathing/breathing_patterns.dart';
import '../features/completion/completion_screen.dart';
import '../shared/lo_fi/lo_fi_screens.dart';
import '../shared/theme/app_theme_mode.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String focusFill = '/focus-fill';
  static const String balancingGame = '/balancing-game';
  static const String thoughtOffloading = '/thought-offloading';
  static const String breathing = '/breathing';
  static const String breathingSession = '/breathing/session';
  static const String completion = '/completion';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  final lowFi = AppThemeMode.instance.lowFi;
  final Widget page;
  switch (settings.name) {
    case AppRoutes.home:
      page = const HomeScreen();
    case AppRoutes.focusFill:
      page = lowFi ? const LoFiFocusFillScreen() : const FocusFillScreen();
    case AppRoutes.balancingGame:
      page = lowFi
          ? const LoFiBalancingGameScreen()
          : const BalancingGameScreen();
    case AppRoutes.thoughtOffloading:
      page = lowFi
          ? const LoFiThoughtOffloadingScreen()
          : const ThoughtOffloadingScreen();
    case AppRoutes.breathing:
      page = const BreathingSelectionScreen();
    case AppRoutes.breathingSession:
      final args = settings.arguments as BreathingSessionArgs?;
      final pattern = args != null
          ? breathingPatternById(args.patternId)
          : pursedLipPattern;
      page = lowFi
          ? LoFiBreathingSessionScreen(pattern: pattern)
          : BreathingSessionScreen(pattern: pattern);
    case AppRoutes.completion:
      final args = settings.arguments as CompletionArgs? ?? CompletionArgs.empty();
      page = CompletionScreen(args: args);
    default:
      page = const HomeScreen();
  }

  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
