import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_mode.dart';

class BlobBackground extends StatefulWidget {
  final List<Color>? colors;

  const BlobBackground({super.key, this.colors});

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<Offset>> _drifts;

  static const _defaultColors = [
    AppColors.blobPink,
    AppColors.blobBlue,
    AppColors.blobPurple,
    AppColors.blobMint,
  ];

  // Anchor positions (fractional of screen size)
  static const _anchors = [
    Offset(-0.1, -0.05),
    Offset(0.65, -0.1),
    Offset(-0.15, 0.55),
    Offset(0.6, 0.65),
  ];

  static const _driftAmplitude = 0.04; // fraction of screen

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    final rng = Random(42);
    _drifts = List.generate(4, (i) {
      final dx = (rng.nextDouble() - 0.5) * 2 * _driftAmplitude;
      final dy = (rng.nextDouble() - 0.5) * 2 * _driftAmplitude;
      return Tween<Offset>(
        begin: _anchors[i],
        end: _anchors[i] + Offset(dx, dy),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeMode.instance,
      builder: (_, _) {
        if (AppThemeMode.instance.lowFi) {
          return const ColoredBox(
            color: Color(0xFFF0F0F0),
            child: SizedBox.expand(),
          );
        }
        return _buildBlobs();
      },
    );
  }

  Widget _buildBlobs() {
    final colors = widget.colors ?? _defaultColors;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return SizedBox.expand(
            child: Stack(
              children: [
                Container(color: AppColors.background),
                ...List.generate(4, (i) => _buildBlob(context, i, colors)),
                // Frosted glass blur over all blobs
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlob(BuildContext context, int i, List<Color> colors) {
    final size = MediaQuery.of(context).size;
    final pos = _drifts[i].value;
    final blobSize = size.width * (i.isEven ? 0.85 : 0.70);
    return Positioned(
      left: pos.dx * size.width,
      top: pos.dy * size.height,
      child: Container(
        width: blobSize,
        height: blobSize * (i.isOdd ? 0.9 : 0.75),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors[i % colors.length].withAlpha(160),
              colors[i % colors.length].withAlpha(0),
            ],
          ),
        ),
      ),
    );
  }
}
