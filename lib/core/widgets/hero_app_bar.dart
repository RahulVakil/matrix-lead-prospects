import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Custom hero header used inside HeroScaffold. Sits on the navy backdrop,
/// extends behind status bar via the parent's SafeArea(top: false).
///
/// Use [HeroAppBar.simple] for back-button + title screens. Use the default
/// constructor when you want full control over the trailing/leading slots.
class HeroAppBar extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final List<Widget>? actions;
  final double height;
  final EdgeInsets contentPadding;

  const HeroAppBar({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.actions,
    this.height = 92,
    this.contentPadding = const EdgeInsets.fromLTRB(14, 4, 14, 14),
  });

  /// Convenience constructor: back arrow + plain string title (+ optional subtitle).
  factory HeroAppBar.simple({
    Key? key,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    VoidCallback? onBack,
    bool showBack = true,
  }) {
    return HeroAppBar(
      key: key,
      leading: showBack
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                splashRadius: 22,
              ),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: contentPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.white),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}
