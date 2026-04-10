import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';

class CompassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? radius;

  const CompassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? AppDimensions.cardRadius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfacePrimary,
        borderRadius: r,
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: box,
      ),
    );
  }
}
