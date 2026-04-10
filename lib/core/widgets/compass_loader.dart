import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CompassLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const CompassLoader({
    super.key,
    this.size = 32,
    this.color,
    this.strokeWidth = 2.5,
  });

  const CompassLoader.small({super.key})
      : size = 18,
        color = null,
        strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color ?? AppColors.navyPrimary,
        ),
      ),
    );
  }
}
