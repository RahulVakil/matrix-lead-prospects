import 'package:flutter/material.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/compass_button.dart';

/// Confirmation sheet shown before taking the RM to the IB Lead capture form.
/// Lists the source-lead context that will be carried into the IB form so
/// the RM can verify before converting.
Future<bool?> showConvertToIbSheet(BuildContext context, LeadModel lead) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConvertToIbSheet(lead: lead),
  );
}

class _ConvertToIbSheet extends StatelessWidget {
  final LeadModel lead;
  const _ConvertToIbSheet({required this.lead});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_horiz,
                      size: 18, color: AppColors.navyPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Convert to IB Lead',
                    style: AppTextStyles.heading3
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These details will be carried into the IB Lead form. You can edit any of them there.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Name', lead.fullName),
                  if ((lead.companyName ?? '').isNotEmpty)
                    _row('Company', lead.companyName!),
                  _row('Phone', lead.phone),
                  if ((lead.email ?? '').isNotEmpty) _row('Email', lead.email!),
                  if ((lead.city ?? '').isNotEmpty) _row('City', lead.city!),
                  if (lead.estimatedAum != null)
                    _row('Est. AUM',
                        IndianCurrencyFormatter.shortForm(lead.estimatedAum!)),
                  if (lead.productInterest.isNotEmpty)
                    _row('Product interest', lead.productInterest.join(', ')),
                  if ((lead.notes ?? '').isNotEmpty)
                    _row('Notes', _truncate(lead.notes!, 140)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: CompassButton(
                    label: 'Cancel',
                    variant: CompassButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CompassButton(
                    label: 'Convert & Continue',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
