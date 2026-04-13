import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Lightweight AppBar matching compass design. Used by screens that still
/// use Scaffold(appBar:) pattern instead of HeroScaffold.
class CompassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CompassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.navyPrimary,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      title: subtitle == null
          ? Text(title, style: AppTextStyles.heading3.copyWith(color: Colors.white))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                Text(subtitle!, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
      actions: actions,
      bottom: bottom,
    );
  }
}
