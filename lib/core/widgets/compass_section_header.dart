import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CompassSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final int? count;
  final Color? color;

  const CompassSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            letterSpacing: 1.2,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ],
        const Spacer(),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.navyPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
