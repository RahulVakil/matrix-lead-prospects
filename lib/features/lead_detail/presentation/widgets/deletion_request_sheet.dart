import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';

/// DPDP right to erasure — request permanent deletion of a lead's PII.
/// Requires admin approval (modelled but deferred to admin flow).
Future<bool?> showDeletionRequestSheet(BuildContext context, String leadName) {
  return showCompassSheet<bool>(
    context,
    isDismissible: false,
    child: _DeletionBody(leadName: leadName),
  );
}

class _DeletionBody extends StatelessWidget {
  final String leadName;
  const _DeletionBody({required this.leadName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.errorRed.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_forever, color: AppColors.errorRed, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Request data deletion',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'This will mark all personal data for "$leadName" for permanent deletion. '
          'This action requires admin approval and cannot be undone.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warmAmber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.warmAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Per DPDP Act 2023 — Right to Erasure (Section 12)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warmAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CompassButton.danger(
          label: 'Confirm deletion request',
          icon: Icons.delete_outline,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        CompassButton.tertiary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
