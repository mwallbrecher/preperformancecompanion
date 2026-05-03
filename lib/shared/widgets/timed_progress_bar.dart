import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TimedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double height;

  const TimedProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.accent,
    this.height = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth,
                height: height,
                color: AppColors.buttonBorder.withAlpha(80),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
