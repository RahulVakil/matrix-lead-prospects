import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CompassButtonVariant { primary, secondary, tertiary, danger }

/// Compass-aligned button. Mirrors InstaKycPrimaryButton:
/// 50px height, 28px radius, inline spinner when loading,
/// disabled at 50% opacity.
class CompassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CompassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CompassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CompassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  const CompassButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = CompassButtonVariant.secondary;

  const CompassButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = CompassButtonVariant.tertiary;

  const CompassButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = CompassButtonVariant.danger;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final height = 50.0;
    final radius = BorderRadius.circular(28);

    Widget content;
    if (isLoading) {
      content = const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textOnDark,
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      content = Text(label);
    }

    final btn = switch (variant) {
      CompassButtonVariant.primary => ElevatedButton(
          onPressed: _enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyPrimary,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: AppColors.navyPrimary.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.textOnDark,
            minimumSize: Size.fromHeight(height),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: content,
        ),
      CompassButtonVariant.secondary => OutlinedButton(
          onPressed: _enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navyPrimary,
            minimumSize: Size.fromHeight(height),
            side: BorderSide(
              color: _enabled ? AppColors.navyPrimary : AppColors.borderDisabled,
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: content,
        ),
      CompassButtonVariant.tertiary => TextButton(
          onPressed: _enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navyPrimary,
            minimumSize: Size.fromHeight(height),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: content,
        ),
      CompassButtonVariant.danger => ElevatedButton(
          onPressed: _enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRedAlt,
            foregroundColor: AppColors.textOnDark,
            disabledBackgroundColor: AppColors.errorRedAlt.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.textOnDark,
            minimumSize: Size.fromHeight(height),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: content,
        ),
    };

    return isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
