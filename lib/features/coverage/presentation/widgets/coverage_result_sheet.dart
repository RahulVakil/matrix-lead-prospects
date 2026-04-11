import 'package:flutter/material.dart';
import '../../../../core/models/client_master_record.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';

/// Coverage result sheet — used by both Wealth (Create Lead, action-driven) and
/// IB (Capture, read-only). Action-driven mode returns a [CoverageDecision];
/// read-only mode returns null.
///
/// Renders the matched record (or alternate matches list when status is
/// requiresReview) with appropriate actions.
Future<CoverageDecision?> showCoverageResultSheet(
  BuildContext context,
  CoverageCheckResult result, {
  bool readOnly = false,
}) {
  return showCompassSheet<CoverageDecision>(
    context,
    title: 'Coverage check',
    isDismissible: readOnly,
    child: _CoverageResultBody(result: result, readOnly: readOnly),
  );
}

enum CoverageDecision { cancel, requestReassignment, saveAnyway, proceed }

class _CoverageResultBody extends StatelessWidget {
  final CoverageCheckResult result;
  final bool readOnly;
  const _CoverageResultBody({required this.result, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(result.status);
    final icon = _statusIcon(result.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header banner with status colour
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Single match details
        if (result.matchedRecord != null && result.alternateMatches.isEmpty) ...[
          const SizedBox(height: 16),
          _MatchCard(record: result.matchedRecord!),
        ],

        // Alternate matches list (requiresReview)
        if (result.alternateMatches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${result.alternateMatches.length} POSSIBLE MATCHES',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: List.generate(result.alternateMatches.length, (i) {
                final isLast = i == result.alternateMatches.length - 1;
                return Column(
                  children: [
                    _AlternateMatchRow(record: result.alternateMatches[i]),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 14),
                        color: AppColors.borderDefault.withValues(alpha: 0.4),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],

        const SizedBox(height: 20),
        ..._actionsFor(context),
      ],
    );
  }

  List<Widget> _actionsFor(BuildContext context) {
    if (readOnly) {
      return [
        CompassButton.tertiary(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
    }
    switch (result.status) {
      case CoverageStatus.existingClient:
        return [
          CompassButton.danger(
            label: 'Request reassignment',
            onPressed: () =>
                Navigator.of(context).pop(CoverageDecision.requestReassignment),
          ),
          const SizedBox(height: 10),
          CompassButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(CoverageDecision.cancel),
          ),
        ];
      case CoverageStatus.duplicateLead:
        return [
          CompassButton(
            label: 'Save anyway',
            onPressed: () =>
                Navigator.of(context).pop(CoverageDecision.saveAnyway),
          ),
          const SizedBox(height: 10),
          CompassButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(CoverageDecision.cancel),
          ),
        ];
      case CoverageStatus.requiresReview:
        return [
          CompassButton(
            label: 'Continue capture',
            onPressed: () => Navigator.of(context).pop(CoverageDecision.proceed),
          ),
          const SizedBox(height: 10),
          CompassButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(CoverageDecision.cancel),
          ),
        ];
      default:
        return [
          CompassButton(
            label: 'Continue',
            onPressed: () =>
                Navigator.of(context).pop(CoverageDecision.proceed),
          ),
        ];
    }
  }

  Color _statusColor(CoverageStatus s) {
    switch (s) {
      case CoverageStatus.existingClient:
        return AppColors.errorRed;
      case CoverageStatus.duplicateLead:
        return AppColors.warmAmber;
      case CoverageStatus.requiresReview:
        return AppColors.tealAccent;
      case CoverageStatus.dnd:
        return AppColors.errorRed;
      case CoverageStatus.clear:
        return AppColors.successGreen;
    }
  }

  IconData _statusIcon(CoverageStatus s) {
    switch (s) {
      case CoverageStatus.existingClient:
        return Icons.shield;
      case CoverageStatus.duplicateLead:
        return Icons.warning_amber_rounded;
      case CoverageStatus.requiresReview:
        return Icons.search;
      case CoverageStatus.dnd:
        return Icons.do_not_disturb_on_outlined;
      case CoverageStatus.clear:
        return Icons.check_circle_outline;
    }
  }
}

class _MatchCard extends StatelessWidget {
  final ClientMasterRecord record;
  const _MatchCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _row('Name', record.clientName),
          if (record.groupName != null) _row('Group', record.groupName!),
          if (record.rmName != null) _row('Owning RM', record.rmName!),
          if (record.city != null) _row('City', record.city!),
          _row('Source', record.source.label),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternateMatchRow extends StatelessWidget {
  final ClientMasterRecord record;
  const _AlternateMatchRow({required this.record});

  Color get _sourceColor {
    switch (record.source) {
      case CoverageSource.clientMaster:
        return AppColors.errorRed;
      case CoverageSource.companyMaster:
        return AppColors.tealAccent;
      case CoverageSource.leadList:
        return AppColors.warmAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _sourceColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.clientName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.groupName ?? '—'} · ${record.rmName ?? 'No RM'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _sourceColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.source.label,
              style: AppTextStyles.caption.copyWith(
                color: _sourceColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
