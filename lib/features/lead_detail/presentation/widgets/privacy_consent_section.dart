import 'package:flutter/material.dart';
import '../../../../core/enums/consent_type.dart';
import '../../../../core/models/consent_record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Lead Detail collapsible section showing DPDP consent records.
class PrivacyConsentSection extends StatefulWidget {
  final ConsentStatus status;
  final List<ConsentRecord> records;
  final VoidCallback onRecordConsent;
  final VoidCallback onRevokeConsent;

  const PrivacyConsentSection({
    super.key,
    required this.status,
    required this.records,
    required this.onRecordConsent,
    required this.onRevokeConsent,
  });

  @override
  State<PrivacyConsentSection> createState() => _PrivacyConsentSectionState();
}

class _PrivacyConsentSectionState extends State<PrivacyConsentSection> {
  bool _open = false;

  Color get _statusColor => switch (widget.status) {
        ConsentStatus.granted => AppColors.successGreen,
        ConsentStatus.partial => AppColors.warmAmber,
        ConsentStatus.revoked => AppColors.errorRed,
        ConsentStatus.pending => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: _statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PRIVACY & CONSENT',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status.label,
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        if (widget.records.isEmpty)
                          Text(
                            'No consent recorded yet.',
                            style: AppTextStyles.bodySmall,
                          )
                        else
                          ...widget.records.map((r) => _ConsentRow(record: r)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: widget.onRecordConsent,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Record consent'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.tealAccent,
                                ),
                              ),
                            ),
                            if (widget.status == ConsentStatus.granted)
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: widget.onRevokeConsent,
                                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                                  label: const Text('Revoke'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final ConsentRecord record;
  const _ConsentRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isActive = record.isActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isActive ? AppColors.successGreen : AppColors.errorRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.consentType.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.statusDisplay} · ${record.grantedAt.day}/${record.grantedAt.month}/${record.grantedAt.year}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
