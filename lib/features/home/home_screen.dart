import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../debug/debug_service.dart';
import '../../debug/debug_panel.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/theme/app_theme_mode.dart';
import '../../shared/widgets/blob_background.dart';
import 'widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _debugVisible = false;

  void _navigateTo(String route, String featureName) {
    DebugService.instance.logEvent(
      screen: 'home',
      eventType: 'feature_select',
      elementId: featureName,
    );
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onLongPress: () {
          DebugService.instance.logEvent(
            screen: 'home',
            eventType: 'debug_panel_toggle',
            elementId: 'long_press',
          );
          setState(() => _debugVisible = !_debugVisible);
        },
        child: Stack(
          children: [
            const BlobBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),
                    Text(
                      'What do you\nneed right now?',
                      style: AppTextStyles.prompt,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose what feels most true.',
                      style: AppTextStyles.promptSecondary,
                    ),
                    const Spacer(),
                    FeatureCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Focus Fill',
                      subtitle: 'Just be still and watch it fill',
                      accentColor: AppColors.fillBottom,
                      onTap: () => _navigateTo(AppRoutes.focusFill, 'focus_fill'),
                    ),
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: AppThemeMode.instance,
                      builder: (_, _) {
                        final lowFi = AppThemeMode.instance.lowFi;
                        return FeatureCard(
                          icon: Icons.sports_esports_outlined,
                          title: lowFi ? 'Balance Game' : 'Distract Me',
                          subtitle: lowFi
                              ? 'Tilt your phone to reset your mind'
                              : 'Balance Game which distracts you from your thoughts',
                          accentColor: AppColors.ballGradientB,
                          onTap: () => _navigateTo(
                              AppRoutes.balancingGame, 'balancing_game'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FeatureCard(
                      icon: Icons.mic_none_outlined,
                      title: 'Offload',
                      subtitle: 'Say what\'s on your mind out loud',
                      accentColor: AppColors.nodeA,
                      onTap: () => _navigateTo(AppRoutes.thoughtOffloading, 'thought_offloading'),
                    ),
                    const SizedBox(height: 12),
                    FeatureCard(
                      icon: Icons.air_rounded,
                      title: 'Breathe',
                      subtitle: 'Three guided breathing techniques',
                      accentColor: AppColors.blobPurple,
                      onTap: () => _navigateTo(AppRoutes.breathing, 'breathing'),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            // Debug panel overlay
            if (_debugVisible)
              DebugPanel(onClose: () => setState(() => _debugVisible = false)),
          ],
        ),
      ),
    );
  }
}
