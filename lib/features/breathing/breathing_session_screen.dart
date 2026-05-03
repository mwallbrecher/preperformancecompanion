import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../features/completion/completion_screen.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/blob_background.dart';
import '../../shared/widgets/timed_progress_bar.dart';
import 'breathing_notifier.dart';
import 'breathing_patterns.dart';
import 'widgets/box_painter.dart';
import 'widgets/orb_painter.dart';
import 'widgets/pursed_lip_painter.dart';

class BreathingSessionArgs {
  final BreathingPatternId patternId;
  const BreathingSessionArgs({required this.patternId});
}

class BreathingSessionScreen extends StatefulWidget {
  final BreathingPattern pattern;
  const BreathingSessionScreen({super.key, required this.pattern});

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen>
    with TickerProviderStateMixin {
  late BreathingNotifier _notifier;
  late AnimationController _shimmerCtrl; // only used by 4-7-8 orb
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _notifier = BreathingNotifier(pattern: widget.pattern);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _notifier.addListener(_onNotifierUpdate);

    DebugService.instance.logEvent(
      screen: 'breathing_session',
      eventType: 'nav',
      elementId: widget.pattern.id.name,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.start(this);
      DebugService.instance.logEvent(
        screen: 'breathing_session',
        eventType: 'session_start',
        elementId: widget.pattern.id.name,
      );
    });
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierUpdate);
    _notifier.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _onNotifierUpdate() {
    if (_notifier.isComplete && !_hasNavigated) {
      _hasNavigated = true;
      DebugService.instance.logEvent(
        screen: 'breathing_session',
        eventType: 'session_end',
        elementId: 'auto_complete_${_notifier.completedCycles}cycles',
      );
      Future.microtask(_navigateToCompletion);
    }
  }

  void _navigateToCompletion() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.completion,
      arguments: CompletionArgs(
        featureName: 'breathing_${widget.pattern.id.name}',
        durationSeconds: _notifier.totalElapsed.inSeconds,
      ),
    );
  }

  void _onDoneEarly() {
    DebugService.instance.logEvent(
      screen: 'breathing_session',
      eventType: 'session_end',
      elementId: 'manual_done_${_notifier.completedCycles}cycles',
    );
    _hasNavigated = true;
    _notifier.stop();
    _navigateToCompletion();
  }

  void _onModeChange(bool touch) {
    if (_notifier.touchMode == touch) return;
    _notifier.setTouchMode(touch);
    DebugService.instance.logEvent(
      screen: 'breathing_session',
      eventType: 'tap',
      elementId: touch ? 'mode_touch' : 'mode_basic',
    );
  }

  /// Short instruction for touch mode — tells the user what physical action
  /// is expected during the current phase.
  String _touchHint() {
    switch (_notifier.currentPhase.action) {
      case BreathingAction.inhale:
      case BreathingAction.holdEmpty:
        return 'Lift your finger';
      case BreathingAction.exhale:
      case BreathingAction.hold:
        return 'Press & hold';
    }
  }

  void _onExit() {
    DebugService.instance.logEvent(
      screen: 'breathing_session',
      eventType: 'nav',
      elementId: 'exit_button',
    );
    _notifier.stop();
    _hasNavigated = true;
    Navigator.of(context).pop();
  }

  Widget _buildPainter() {
    switch (widget.pattern.id) {
      case BreathingPatternId.pursedLip:
        return CustomPaint(
          painter: PursedLipPainter(
            action: _notifier.currentPhase.action,
            phaseProgress: _notifier.phaseProgress,
            coolColor: widget.pattern.primaryColor,
            warmColor: widget.pattern.accentColor,
          ),
        );
      case BreathingPatternId.fourSevenEight:
        return AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, _) => CustomPaint(
            painter: OrbPainter(
              action: _notifier.currentPhase.action,
              phaseProgress: _notifier.phaseProgress,
              wavePhase: _shimmerCtrl.value * 2 * pi,
              primaryColor: widget.pattern.primaryColor,
              accentColor: widget.pattern.accentColor,
            ),
          ),
        );
      case BreathingPatternId.box:
        return CustomPaint(
          painter: BreathingBoxPainter(
            phaseIndex: _notifier.currentPhaseIndex,
            phaseProgress: _notifier.phaseProgress,
            action: _notifier.currentPhase.action,
            primaryColor: widget.pattern.primaryColor,
            accentColor: widget.pattern.accentColor,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          BlobBackground(
            colors: [
              widget.pattern.primaryColor,
              widget.pattern.accentColor,
              AppColors.blobMint,
              AppColors.blobBlue,
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar: overall progress + exit ────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _notifier,
                          builder: (_, _) => TimedProgressBar(
                            progress: _notifier.overallProgress,
                            color: widget.pattern.accentColor.withAlpha(200),
                            height: 3,
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
                            color: Colors.white.withAlpha(120),
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

                // ── Mode toggle (pursed-lip only) ───────────────────────
                if (widget.pattern.id == BreathingPatternId.pursedLip)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: ListenableBuilder(
                      listenable: _notifier,
                      builder: (_, _) => _ModeToggle(
                        touchMode: _notifier.touchMode,
                        accentColor: widget.pattern.accentColor,
                        onChanged: _onModeChange,
                      ),
                    ),
                  ),

                // ── Visualisation canvas ────────────────────────────────
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _notifier.setTouching(true),
                    onPointerUp: (_) => _notifier.setTouching(false),
                    onPointerCancel: (_) => _notifier.setTouching(false),
                    child: RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _notifier,
                        builder: (_, _) => SizedBox.expand(
                          child: _buildPainter(),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Phase label + countdown ─────────────────────────────
                ListenableBuilder(
                  listenable: _notifier,
                  builder: (_, _) {
                    final phase = _notifier.currentPhase;
                    return Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            phase.label,
                            key: ValueKey(
                                '${_notifier.currentPhaseIndex}_${_notifier.completedCycles}'),
                            style: AppTextStyles.prompt.copyWith(
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_notifier.phaseSecondsRemaining}',
                          style: AppTextStyles.promptSecondary.copyWith(
                            fontSize: 20,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _notifier.touchMode ? 1 : 0,
                          child: Text(
                            _touchHint(),
                            style: AppTextStyles.promptSecondary.copyWith(
                              fontSize: 13,
                              letterSpacing: 0.4,
                              color: _notifier.isInSync
                                  ? AppColors.textSecondary
                                  : widget.pattern.accentColor,
                              fontWeight: _notifier.isInSync
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Early "Done" — appears after first full cycle ────────
                SizedBox(
                  height: 52,
                  child: ListenableBuilder(
                    listenable: _notifier,
                    builder: (_, _) {
                      if (_notifier.completedCycles < 1) {
                        return const SizedBox.shrink();
                      }
                      return AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 500),
                        child: GestureDetector(
                          onTap: _onDoneEarly,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 26, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: AppColors.buttonBorder, width: 1),
                            ),
                            child: Text(
                              'Done',
                              style: AppTextStyles.ghostButton,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented pill toggle for Basic / Touch mode.
class _ModeToggle extends StatelessWidget {
  final bool touchMode;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.touchMode,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(120),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.buttonBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment('Basic', !touchMode, () => onChanged(false)),
            _segment('Touch', touchMode, () => onChanged(true)),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accentColor.withAlpha(180) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: AppTextStyles.ghostButton.copyWith(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
