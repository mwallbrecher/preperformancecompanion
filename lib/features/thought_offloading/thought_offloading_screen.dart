import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../features/completion/completion_screen.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/blob_background.dart';
import '../../shared/widgets/ghost_button.dart';
import 'thought_offloading_notifier.dart';
import 'widgets/mic_button.dart';
import 'widgets/node_graph_view.dart';

class ThoughtOffloadingScreen extends StatefulWidget {
  const ThoughtOffloadingScreen({super.key});

  @override
  State<ThoughtOffloadingScreen> createState() =>
      _ThoughtOffloadingScreenState();
}

class _ThoughtOffloadingScreenState extends State<ThoughtOffloadingScreen> {
  late ThoughtOffloadingNotifier _notifier;
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    _notifier = ThoughtOffloadingNotifier();
    _sessionStart = DateTime.now();

    DebugService.instance.logEvent(
      screen: 'thought_offloading',
      eventType: 'nav',
      elementId: 'screen_open',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _notifier.setScreenSize(size.width, size.height);
      _notifier.initialize();
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_notifier.isListening) {
      await _notifier.stopListening();
      DebugService.instance.logEvent(
        screen: 'thought_offloading',
        eventType: 'tap',
        elementId: 'mic_stop',
      );
    } else {
      await _notifier.startListening();
      DebugService.instance.logEvent(
        screen: 'thought_offloading',
        eventType: 'tap',
        elementId: 'mic_start',
      );
    }
  }

  void _onReset() {
    // Stop mic first (fire-and-forget — no await so context stays sync)
    if (_notifier.isListening) _notifier.stopListening();

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete notes?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'All your thought bubbles will be permanently removed.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _notifier.clearNodes();
        DebugService.instance.logEvent(
          screen: 'thought_offloading',
          eventType: 'reset',
          elementId: 'nodes_cleared',
        );
      }
    });
  }

  void _onDone() {
    final duration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inSeconds
        : 0;
    DebugService.instance.logEvent(
      screen: 'thought_offloading',
      eventType: 'session_end',
      elementId: 'nodes_${_notifier.nodes.length}',
    );
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.completion,
      arguments: CompletionArgs(
        featureName: 'thought_offloading',
        durationSeconds: duration,
      ),
    );
  }

  void _onExit() {
    DebugService.instance.logEvent(
      screen: 'thought_offloading',
      eventType: 'nav',
      elementId: 'exit_button',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BlobBackground(
            colors: [
              AppColors.nodeA,
              AppColors.nodeB,
              AppColors.blobPink,
              AppColors.blobMint,
            ],
          ),

          // Node graph — full screen behind UI
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _notifier,
              builder: (_, _) => NodeGraphView(nodes: _notifier.nodes),
            ),
          ),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reset (trash) — only shown when there are nodes
                      ListenableBuilder(
                        listenable: _notifier,
                        builder: (_, _) {
                          if (_notifier.nodes.isEmpty) {
                            return const SizedBox(width: 36);
                          }
                          return GestureDetector(
                            onTap: _onReset,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(100),
                                border: Border.all(
                                    color: AppColors.buttonBorder),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),

                      // Exit
                      GestureDetector(
                        onTap: _onExit,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(100),
                            border:
                                Border.all(color: AppColors.buttonBorder),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Prompt — fades out when nodes exist ───────────────────
                ListenableBuilder(
                  listenable: _notifier,
                  builder: (_, _) {
                    final hasNodes = _notifier.nodes.isNotEmpty;
                    return AnimatedOpacity(
                      opacity: hasNodes ? 0 : 1,
                      duration: const Duration(milliseconds: 600),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          children: [
                            Text(
                              'Say what\'s\non your mind.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.prompt,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap the mic and speak freely.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.promptSecondary,
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 200.ms)
                            .slideY(begin: 0.1, end: 0),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // ── Interim text preview ──────────────────────────────────
                ListenableBuilder(
                  listenable: _notifier,
                  builder: (_, _) {
                    final text = _notifier.interimText;
                    if (text.isEmpty) return const SizedBox(height: 32);
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.promptSecondary.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textGhost,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── Mic button ────────────────────────────────────────────
                ListenableBuilder(
                  listenable: _notifier,
                  builder: (_, _) {
                    if (_notifier.recordingState ==
                        RecordingState.unavailable) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Speech recognition is not available on this device.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.promptSecondary,
                        ),
                      );
                    }
                    return MicButton(
                      isListening: _notifier.isListening,
                      onTap: _toggleMic,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Done button — visible once nodes exist ────────────────
                ListenableBuilder(
                  listenable: _notifier,
                  builder: (_, _) {
                    if (_notifier.nodes.isEmpty) {
                      return const SizedBox(height: 56);
                    }
                    return GhostButton(label: 'Done', onTap: _onDone)
                        .animate()
                        .fadeIn(duration: 500.ms);
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
