import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CompassSnackType { success, error, info, warn }

void showCompassSnack(
  BuildContext context, {
  required String message,
  CompassSnackType type = CompassSnackType.info,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final colors = switch (type) {
    CompassSnackType.success => (AppColors.successGreen, Icons.check_circle_outline),
    CompassSnackType.error => (AppColors.errorRedAlt, Icons.error_outline),
    CompassSnackType.warn => (AppColors.warmAmber, Icons.warning_amber_rounded),
    CompassSnackType.info => (AppColors.navyPrimary, Icons.info_outline),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfacePrimary,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDefault),
        ),
        duration: duration,
        action: action,
        content: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: colors.$1,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(colors.$2, color: colors.$1, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
