import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../features/breathing/breathing_patterns.dart';
import '../../features/completion/completion_screen.dart';
import '../widgets/blob_background.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Low-fidelity wireframe screens — shown instead of the real activity
/// screens when [AppThemeMode.lowFi] is on. Used for UX structure testing.
///
/// Mechanics are represented with the simplest possible visual (one-colour
/// shapes, placeholder text, slow animations). No sensors, speech, physics.
/// Each screen keeps the navigation contract so participants can walk the
/// full flow.
/// ─────────────────────────────────────────────────────────────────────────

const _inkColor = Color(0xFF1A1A1A);
const _mutedColor = Color(0xFF777777);
const _fillColor = Color(0xFF999999);

class _LoFiScaffold extends StatelessWidget {
  final String title;
  final String featureName;
  final Widget body;

  const _LoFiScaffold({
    required this.title,
    required this.featureName,
    required this.body,
  });

  void _onClose(BuildContext context) {
    DebugService.instance.logEvent(
      screen: 'lofi_$featureName',
      eventType: 'nav',
      elementId: 'exit_button',
    );
    Navigator.of(context).pop();
  }

  void _onDone(BuildContext context) {
    DebugService.instance.logEvent(
      screen: 'lofi_$featureName',
      eventType: 'session_end',
      elementId: 'lofi_done',
    );
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.completion,
      arguments: CompletionArgs(featureName: featureName, durationSeconds: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BlobBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _inkColor,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _onClose(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _mutedColor),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _inkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: body),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 12),
                  child: GestureDetector(
                    onTap: () => _onDone(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _inkColor, width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 14, color: _inkColor),
                      ),
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

// ── Focus Fill: one-colour wave slowly filling up ──────────────────────────
class LoFiFocusFillScreen extends StatefulWidget {
  const LoFiFocusFillScreen({super.key});

  @override
  State<LoFiFocusFillScreen> createState() => _LoFiFocusFillScreenState();
}

class _LoFiFocusFillScreenState extends State<LoFiFocusFillScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fill;
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    DebugService.instance.logEvent(
      screen: 'lofi_focus_fill',
      eventType: 'session_start',
      elementId: 'lofi_open',
    );
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..forward();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _fill.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoFiScaffold(
      title: 'Focus Fill',
      featureName: 'focus_fill',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _inkColor, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([_fill, _wave]),
              builder: (_, _) => CustomPaint(
                painter: _LoFiWavePainter(
                  fillLevel: _fill.value,
                  wavePhase: _wave.value * 2 * pi,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoFiWavePainter extends CustomPainter {
  final double fillLevel;
  final double wavePhase;
  _LoFiWavePainter({required this.fillLevel, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * (1 - fillLevel);
    const amp = 8.0;
    const wavelength = 120.0;

    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    for (double x = 0; x <= size.width; x += 4) {
      final y = baseY + sin((x / wavelength) * 2 * pi + wavePhase) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = _fillColor);
  }

  @override
  bool shouldRepaint(_LoFiWavePainter old) =>
      old.fillLevel != fillLevel || old.wavePhase != wavePhase;
}

// ── Balance game: static maze sketch ───────────────────────────────────────
class LoFiBalancingGameScreen extends StatelessWidget {
  const LoFiBalancingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DebugService.instance.logEvent(
      screen: 'lofi_balancing_game',
      eventType: 'session_start',
      elementId: 'lofi_open',
    );
    return _LoFiScaffold(
      title: 'Balance Game',
      featureName: 'balancing_game',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: 0.6,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _inkColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: _LoFiMazePainter(),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoFiMazePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..color = _inkColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Simple maze skeleton — normalized lines
    final lines = <List<double>>[
      [0.0,  0.20, 0.65, 0.20],
      [0.35, 0.35, 1.00, 0.35],
      [0.15, 0.50, 0.85, 0.50],
      [0.00, 0.65, 0.55, 0.65],
      [0.45, 0.80, 1.00, 0.80],
      [0.30, 0.20, 0.30, 0.50],
      [0.70, 0.35, 0.70, 0.65],
      [0.25, 0.65, 0.25, 0.80],
    ];
    for (final l in lines) {
      canvas.drawLine(
        Offset(l[0] * w, l[1] * h),
        Offset(l[2] * w, l[3] * h),
        wall,
      );
    }

    // Ball — static
    canvas.drawCircle(
      Offset(w * 0.15, h * 0.10),
      10,
      Paint()..color = _fillColor,
    );
  }

  @override
  bool shouldRepaint(_LoFiMazePainter old) => false;
}

// ── Thought Offloading: mic + placeholder bubbles ──────────────────────────
class LoFiThoughtOffloadingScreen extends StatelessWidget {
  const LoFiThoughtOffloadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DebugService.instance.logEvent(
      screen: 'lofi_thought_offloading',
      eventType: 'session_start',
      elementId: 'lofi_open',
    );
    return _LoFiScaffold(
      title: 'Offload',
      featureName: 'thought_offloading',
      body: Stack(
        children: [
          // Placeholder bubbles scattered across the canvas
          const Positioned(
            left: 40, top: 40,
            child: _ThoughtBubble(text: 'presentation'),
          ),
          const Positioned(
            right: 30, top: 90,
            child: _ThoughtBubble(text: 'timing'),
          ),
          const Positioned(
            left: 60, top: 170,
            child: _ThoughtBubble(text: 'slide three'),
          ),
          const Positioned(
            right: 50, top: 230,
            child: _ThoughtBubble(text: 'breathe'),
          ),
          const Positioned(
            left: 30, bottom: 120,
            child: _ThoughtBubble(text: 'questions'),
          ),
          // Mic in the centre-bottom
          Align(
            alignment: const Alignment(0, 0.7),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _inkColor, width: 1.5),
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                size: 36,
                color: _inkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThoughtBubble extends StatelessWidget {
  final String text;
  const _ThoughtBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _fillColor.withAlpha(60),
        border: Border.all(color: _mutedColor, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _inkColor),
      ),
    );
  }
}

// ── Breathe: circle + cycling inhale/exhale label ──────────────────────────
class LoFiBreathingSessionScreen extends StatefulWidget {
  final BreathingPattern pattern;
  const LoFiBreathingSessionScreen({super.key, required this.pattern});

  @override
  State<LoFiBreathingSessionScreen> createState() =>
      _LoFiBreathingSessionScreenState();
}

class _LoFiBreathingSessionScreenState
    extends State<LoFiBreathingSessionScreen> {
  bool _inhaling = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    DebugService.instance.logEvent(
      screen: 'lofi_breathing_session',
      eventType: 'session_start',
      elementId: 'lofi_${widget.pattern.id.name}',
    );
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _inhaling = !_inhaling);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoFiScaffold(
      title: 'Breathe · ${widget.pattern.techniqueName}',
      featureName: 'breathing_${widget.pattern.id.name}',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _inhaling ? 'Inhale' : 'Exhale',
              key: ValueKey(_inhaling),
              style: const TextStyle(
                fontSize: 18,
                color: _inkColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _fillColor,
            ),
          ),
        ],
      ),
    );
  }
}
