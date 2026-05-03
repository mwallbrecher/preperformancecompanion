import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_text_styles.dart';

class DurationPickerSheet extends StatelessWidget {
  const DurationPickerSheet({super.key});

  static const _options = [
    (label: '30 sec', duration: Duration(seconds: 30)),
    (label: '1 min', duration: Duration(minutes: 1)),
    (label: '2 min', duration: Duration(minutes: 2)),
    (label: '3 min', duration: Duration(minutes: 3)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.buttonBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('How long?', style: AppTextStyles.prompt),
          const SizedBox(height: 6),
          Text(
            'Choose a duration and begin.',
            style: AppTextStyles.promptSecondary,
          ),
          const SizedBox(height: 24),
          ...(_options.map(
            (opt) => _DurationTile(
              label: opt.label,
              duration: opt.duration,
            ),
          )),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String label;
  final Duration duration;

  const _DurationTile({required this.label, required this.duration});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(duration),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.buttonBorder.withAlpha(100)),
        ),
        child: Text(label, style: AppTextStyles.durationOption),
      ),
    );
  }
}
