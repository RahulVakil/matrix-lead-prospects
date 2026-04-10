import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CompassBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Widget? child;
  final double offsetRight;
  final double offsetTop;

  const CompassBadge({
    super.key,
    required this.count,
    this.color = AppColors.errorRed,
    this.child,
    this.offsetRight = -6,
    this.offsetTop = -6,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && child != null) return child!;
    final pill = Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfacePrimary, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );

    if (child == null) return pill;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        if (count > 0)
          Positioned(right: offsetRight, top: offsetTop, child: pill),
      ],
    );
  }
}
