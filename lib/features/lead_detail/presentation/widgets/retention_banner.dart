import 'package:flutter/material.dart';
import '../../../../core/enums/retention_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';

/// DPDP retention banner — shown when a lead has been inactive 180+ days.
class RetentionBanner extends StatelessWidget {
  final RetentionStatus status;
  final int daysOverdue;
  final VoidCallback onExtend;
  final VoidCallback onDelete;

  const RetentionBanner({
    super.key,
    required this.status,
    required this.daysOverdue,
    required this.onExtend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (status == RetentionStatus.active || status == RetentionStatus.deleted) {
      return const SizedBox.shrink();
    }

    final color = status == RetentionStatus.markedForDeletion
        ? AppColors.errorRed
        : AppColors.warmAmber;
    final title = status == RetentionStatus.markedForDeletion
        ? 'Deletion requested'
        : status == RetentionStatus.retentionExtended
            ? 'Retention extended'
            : 'Retention review needed';
    final subtitle = status == RetentionStatus.markedForDeletion
        ? 'Pending admin approval for permanent deletion'
        : 'Inactive $daysOverdue+ days. Per DPDP policy, review required.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == RetentionStatus.markedForDeletion
                    ? Icons.delete_outline
                    : Icons.schedule,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodySmall),
          if (status == RetentionStatus.flaggedForReview) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CompassButton.secondary(
                    label: 'Extend 180d',
                    onPressed: onExtend,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CompassButton.danger(
                    label: 'Request deletion',
                    onPressed: onDelete,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
