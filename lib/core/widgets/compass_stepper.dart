import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CompassStepState { completed, current, upcoming }

class CompassStepperItem {
  final String label;
  final IconData icon;
  const CompassStepperItem({required this.label, required this.icon});
}

/// Mirrors compass_v2 instaKycStepper — three states (completed/current/upcoming).
class CompassStepper extends StatelessWidget {
  final List<CompassStepperItem> steps;
  final int currentIndex;

  const CompassStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final beforeIdx = (i - 1) ~/ 2;
          final isFilled = beforeIdx < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isFilled ? AppColors.navyPrimary : AppColors.borderDefault,
            ),
          );
        }
        final idx = i ~/ 2;
        final state = idx < currentIndex
            ? CompassStepState.completed
            : (idx == currentIndex ? CompassStepState.current : CompassStepState.upcoming);
        return _stepDot(steps[idx], state);
      }),
    );
  }

  Widget _stepDot(CompassStepperItem item, CompassStepState state) {
    final color = switch (state) {
      CompassStepState.completed => AppColors.successGreen,
      CompassStepState.current => AppColors.navyPrimary,
      CompassStepState.upcoming => AppColors.borderDefault,
    };
    final icon = state == CompassStepState.completed ? Icons.check : item.icon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: state == CompassStepState.upcoming
                ? AppColors.surfaceTertiary
                : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: state == CompassStepState.current ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: state == CompassStepState.upcoming
                ? AppColors.textHint
                : color,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: state == CompassStepState.upcoming
                  ? AppColors.textHint
                  : color,
              fontWeight: state == CompassStepState.current
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
