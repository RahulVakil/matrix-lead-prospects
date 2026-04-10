import 'package:flutter/material.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';

/// Embedded coverage result shown inside Create Lead when the phone or name
/// blur triggers a coverage hit. Blocks save on existingClient, warns on
/// duplicateLead, surfaces alternates on requiresReview.
Future<CoverageDecision?> showCoverageResultSheet(
  BuildContext context,
  CoverageCheckResult result,
) {
  return showCompassSheet<CoverageDecision>(
    context,
    title: 'Coverage check',
    isDismissible: false,
    child: _CoverageResultBody(result: result),
  );
}

enum CoverageDecision { cancel, requestReassignment, saveAnyway, proceed }

class _CoverageResultBody extends StatelessWidget {
  final CoverageCheckResult result;
  const _CoverageResultBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.status == CoverageStatus.existingClient
        ? AppColors.errorRed
        : result.status == CoverageStatus.duplicateLead
            ? AppColors.warmAmber
            : result.status == CoverageStatus.requiresReview
                ? AppColors.tealAccent
                : AppColors.successGreen;
    final icon = result.status == CoverageStatus.existingClient
        ? Icons.shield
        : result.status == CoverageStatus.duplicateLead
            ? Icons.warning_amber_rounded
            : result.status == CoverageStatus.requiresReview
                ? Icons.search
                : Icons.check_circle_outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (result.matchedRecord != null) ...[
          const SizedBox(height: 16),
          _detailRow('Name', result.matchedRecord!.clientName),
          if (result.matchedRecord!.groupName != null)
            _detailRow('Group', result.matchedRecord!.groupName!),
          if (result.existingRmName != null)
            _detailRow('Owning RM', result.existingRmName!),
          _detailRow('Source', result.matchedRecord!.source.label),
        ],
        const SizedBox(height: 20),
        ..._actionsFor(context),
      ],
    );
  }

  List<Widget> _actionsFor(BuildContext context) {
    switch (result.status) {
      case CoverageStatus.existingClient:
        return [
          CompassButton.danger(
            label: 'Request reassignment',
            onPressed: () => Navigator.of(context).pop(CoverageDecision.requestReassignment),
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
            onPressed: () => Navigator.of(context).pop(CoverageDecision.saveAnyway),
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
            onPressed: () => Navigator.of(context).pop(CoverageDecision.proceed),
          ),
        ];
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
