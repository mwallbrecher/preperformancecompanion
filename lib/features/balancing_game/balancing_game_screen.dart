import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../features/completion/completion_screen.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/blob_background.dart';
import '../../shared/widgets/timed_progress_bar.dart';
import 'balancing_game_notifier.dart';
import 'widgets/game_painter.dart';

class BalancingGameScreen extends StatefulWidget {
  const BalancingGameScreen({super.key});

  @override
  State<BalancingGameScreen> createState() => _BalancingGameScreenState();
}

class _BalancingGameScreenState extends State<BalancingGameScreen>
    with TickerProviderStateMixin {
  late BalancingGameNotifier _notifier;
  bool _hasNavigated = false;
  bool _layoutDone = false;
  bool _gameStarted = false;

  static const double _mazePadding = 12.0;

  @override
  void initState() {
    super.initState();
    _notifier = BalancingGameNotifier();
    _notifier.addListener(_onNotifierUpdate);

    DebugService.instance.logEvent(
      screen: 'balancing_game',
      eventType: 'nav',
      elementId: 'screen_open',
    );
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierUpdate);
    _notifier.dispose();
    super.dispose();
  }

  void _onNotifierUpdate() {
    if (!_gameStarted) return; // ignore notifications before start() is called
    if (!_notifier.isRunning && !_hasNavigated) {
      _hasNavigated = true;
      final reached = _notifier.reachedGoal;
      DebugService.instance.logEvent(
        screen: 'balancing_game',
        eventType: 'session_end',
        elementId: reached ? 'goal_reached' : 'time_expired',
      );
      Future.microtask(() => _navigateToCompletion());
    }
  }

  void _navigateToCompletion() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.completion,
      arguments: CompletionArgs(
        featureName: 'balancing_game',
        durationSeconds: _notifier.elapsedSeconds,
      ),
    );
  }

  void _onExit() {
    DebugService.instance.logEvent(
      screen: 'balancing_game',
      eventType: 'nav',
      elementId: 'exit_button',
    );
    _notifier.stop();
    _hasNavigated = true;
    Navigator.of(context).pop();
  }

  void _setupLayout(BoxConstraints constraints) {
    if (_layoutDone) return;
    _layoutDone = true;

    final canvasW = constraints.maxWidth;
    final canvasH = constraints.maxHeight;
    final cellW = (canvasW - _mazePadding * 2) / _notifier.mazeCols;
    final cellH = (canvasH - _mazePadding * 2) / _notifier.mazeRows;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.setLayout(
        x0: _mazePadding,
        y0: _mazePadding,
        cellW: cellW,
        cellH: cellH,
      );
      _notifier.start(this);
      _gameStarted = true; // arm the completion listener only after start()
      DebugService.instance.logEvent(
        screen: 'balancing_game',
        eventType: 'session_start',
        elementId: 'auto_start',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BlobBackground(
            colors: [
              AppColors.blobMint,
              AppColors.blobBlue,
              AppColors.blobPink,
              AppColors.blobPurple,
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                // ── HUD: progress bar + exit ───────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _notifier,
                          builder: (_, _) => TimedProgressBar(
                            progress: _notifier.timeProgress,
                            color: AppColors.accent.withAlpha(160),
                            height: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _onExit,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(100),
                            border: Border.all(color: AppColors.buttonBorder),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Game canvas ────────────────────────────────────────────
                Expanded(
                  child: RepaintBoundary(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _setupLayout(constraints);
                        return ListenableBuilder(
                          listenable: _notifier,
                          builder: (_, _) {
                            if (!_notifier.layoutReady) {
                              return const SizedBox.expand();
                            }
                            return CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              painter: GamePainter(
                                ballPos: _notifier.ballPos,
                                walls: _notifier.walls,
                                goalRect: _notifier.goalRect,
                                ballRadius: _notifier.ballRadius,
                                wallThickness: _notifier.wallThickness,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
