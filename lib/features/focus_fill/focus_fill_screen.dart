import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../features/completion/completion_screen.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/blob_background.dart';
import 'duration_picker_sheet.dart';
import 'focus_fill_notifier.dart';
import 'widgets/fill_painter.dart';

class FocusFillScreen extends StatefulWidget {
  const FocusFillScreen({super.key});

  @override
  State<FocusFillScreen> createState() => _FocusFillScreenState();
}

class _FocusFillScreenState extends State<FocusFillScreen>
    with TickerProviderStateMixin {
  late FocusFillNotifier _notifier;
  late AnimationController _waveCtrl;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _notifier = FocusFillNotifier();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _notifier.addListener(_onNotifierUpdate);

    DebugService.instance.logEvent(
      screen: 'focus_fill',
      eventType: 'nav',
      elementId: 'screen_open',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _showDurationPicker());
  }

  @override
  void dispose() {
    _notifier.removeListener(_onNotifierUpdate);
    _notifier.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  void _onNotifierUpdate() {
    if (_notifier.state == FillState.complete && !_hasNavigated) {
      _hasNavigated = true;
      _navigateToCompletion();
    }
  }

  Future<void> _showDurationPicker() async {
    final result = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const DurationPickerSheet(),
    );
    if (result != null && mounted) {
      _notifier.setDuration(result);
      _notifier.start(this);
      DebugService.instance.logEvent(
        screen: 'focus_fill',
        eventType: 'session_start',
        elementId: 'duration_${result.inSeconds}s',
      );
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToCompletion() {
    DebugService.instance.logEvent(
      screen: 'focus_fill',
      eventType: 'session_end',
      elementId: 'auto_complete',
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.completion,
      arguments: CompletionArgs(
        featureName: 'focus_fill',
        durationSeconds: _notifier.selectedDuration.inSeconds,
      ),
    );
  }

  void _onReset() {
    DebugService.instance.logEvent(
      screen: 'focus_fill',
      eventType: 'reset',
      elementId: 'reset_button',
    );
    _hasNavigated = false;
    _notifier.reset();
    _showDurationPicker();
  }

  void _onExit() {
    DebugService.instance.logEvent(
      screen: 'focus_fill',
      eventType: 'nav',
      elementId: 'exit_button',
    );
    Navigator.of(context).pop();
  }

  String _formatRemaining() {
    final remaining = _notifier.selectedDuration - _notifier.elapsed;
    final totalSecs = remaining.inSeconds.clamp(0, remaining.inSeconds);
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
          children: [
            // ── Background blobs ────────────────────────────────────────────
            const BlobBackground(
              colors: [
                AppColors.fillTop,
                AppColors.fillBottom,
                AppColors.blobMint,
                AppColors.blobBlue,
              ],
            ),

            // ── Liquid fill ─────────────────────────────────────────────────
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_notifier, _waveCtrl]),
                  builder: (_, _) {
                    final wavePhase = _waveCtrl.value * 2 * pi;
                    return CustomPaint(
                      painter: FillPainter(
                        fillLevel: _notifier.progress,
                        wavePhase: wavePhase,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Countdown label (always visible, subtle) ────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0.15),
                  child: ListenableBuilder(
                    listenable: _notifier,
                    builder: (_, _) {
                      final isRunning = _notifier.state == FillState.running;
                      return AnimatedOpacity(
                        opacity: isRunning ? 0.75 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _formatRemaining(),
                          style: GoogleFonts.dmSans(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Controls (always visible, fade to full on tap) ─────────────
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ControlButton(
                      icon: Icons.replay_rounded,
                      label: 'Reset',
                      onTap: _onReset,
                    ),
                    _ControlButton(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      onTap: _onExit,
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6060A0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6060A0),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
