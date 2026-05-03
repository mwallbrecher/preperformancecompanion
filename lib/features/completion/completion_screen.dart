import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/blob_background.dart';
import '../../shared/widgets/ghost_button.dart';

class CompletionArgs {
  final String featureName;
  final int durationSeconds;

  const CompletionArgs({
    required this.featureName,
    required this.durationSeconds,
  });

  factory CompletionArgs.empty() => const CompletionArgs(
        featureName: 'unknown',
        durationSeconds: 0,
      );
}

class CompletionScreen extends StatefulWidget {
  final CompletionArgs args;

  const CompletionScreen({super.key, required this.args});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    DebugService.instance.logEvent(
      screen: 'completion',
      eventType: 'session_end',
      elementId: widget.args.featureName,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _featureRoute(String featureName) {
    if (featureName.startsWith('breathing_')) {
      return AppRoutes.breathing; // send them back to the technique picker
    }
    switch (featureName) {
      case 'focus_fill':
        return AppRoutes.focusFill;
      case 'balancing_game':
        return AppRoutes.balancingGame;
      case 'thought_offloading':
        return AppRoutes.thoughtOffloading;
      default:
        return AppRoutes.home;
    }
  }

  String get _durationLabel {
    final s = widget.args.durationSeconds;
    if (s < 60) return '${s}s';
    return '${(s / 60).round()}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BlobBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blobMint.withAlpha(120),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('You\'re ready.', style: AppTextStyles.completionTitle),
                    const SizedBox(height: 12),
                    Text(
                      'Session complete · $_durationLabel',
                      style: AppTextStyles.completionBody,
                    ),
                    const Spacer(flex: 4),
                    Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            label: 'Home',
                            onTap: () {
                              DebugService.instance.logEvent(
                                screen: 'completion',
                                eventType: 'nav',
                                elementId: 'back_to_home',
                              );
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.home,
                                (r) => false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GhostButton(
                            label: 'Try Again',
                            onTap: () {
                              DebugService.instance.logEvent(
                                screen: 'completion',
                                eventType: 'nav',
                                elementId: 'try_again',
                              );
                              final route = _featureRoute(widget.args.featureName);
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                route,
                                ModalRoute.withName(AppRoutes.home),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
