import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/blob_background.dart';
import 'breathing_patterns.dart';
import 'breathing_session_screen.dart';

class BreathingSelectionScreen extends StatelessWidget {
  const BreathingSelectionScreen({super.key});

  void _selectPattern(BuildContext context, BreathingPattern pattern) {
    DebugService.instance.logEvent(
      screen: 'breathing_selection',
      eventType: 'tap',
      elementId: pattern.id.name,
    );
    Navigator.of(context).pushNamed(
      AppRoutes.breathingSession,
      arguments: BreathingSessionArgs(patternId: pattern.id),
    );
  }

  void _onExit(BuildContext context) {
    DebugService.instance.logEvent(
      screen: 'breathing_selection',
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
              AppColors.blobMint,
              AppColors.blobPurple,
              AppColors.blobPink,
              AppColors.blobBlue,
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with exit
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _onExit(context),
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

                  const SizedBox(height: 28),

                  Text(
                    'Breathe.',
                    style: AppTextStyles.prompt,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a technique that fits\nhow you feel right now.',
                    style: AppTextStyles.promptSecondary,
                  ),

                  const Spacer(),

                  for (final pattern in breathingPatterns) ...[
                    _PatternCard(
                      pattern: pattern,
                      onTap: () => _selectPattern(context, pattern),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final BreathingPattern pattern;
  final VoidCallback onTap;

  const _PatternCard({required this.pattern, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withAlpha(180),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.buttonBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Colour swatch representing the pattern
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    pattern.primaryColor,
                    pattern.accentColor,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pattern.title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    '${pattern.techniqueName} · ${pattern.rhythmLabel}',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
