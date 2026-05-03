import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double opacity;

  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.buttonBorder, width: 1),
          ),
          child: Text(label, style: AppTextStyles.ghostButton),
        ),
      ),
    );
  }
}
