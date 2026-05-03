import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/theme/app_colors.dart';

class MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const MicButton({super.key, required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppColors.accent.withAlpha(220)
              : AppColors.surfaceCard,
          border: Border.all(
            color: isListening ? AppColors.accent : AppColors.buttonBorder,
            width: isListening ? 2 : 1,
          ),
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ]
              : [],
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
          color: isListening ? Colors.white : AppColors.textSecondary,
          size: 32,
        ),
      )
          .animate(target: isListening ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 800.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 800.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
