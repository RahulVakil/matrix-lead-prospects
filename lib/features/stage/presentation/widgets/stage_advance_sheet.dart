import 'package:flutter/material.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_text_field.dart';

class StageAdvanceSheet extends StatefulWidget {
  final LeadStage currentStage;
  final LeadModel? lead; // for prerequisite checks
  final void Function(LeadStage newStage, String? notes) onAdvance;

  const StageAdvanceSheet({
    super.key,
    required this.currentStage,
    this.lead,
    required this.onAdvance,
  });

  static Future<void> show(
    BuildContext context, {
    required LeadStage currentStage,
    LeadModel? lead,
    required void Function(LeadStage newStage, String? notes) onAdvance,
  }) {
    return showCompassSheet(
      context,
      title: 'Advance stage',
      child: StageAdvanceSheet(
        currentStage: currentStage,
        lead: lead,
        onAdvance: onAdvance,
      ),
    );
  }

  @override
  State<StageAdvanceSheet> createState() => _StageAdvanceSheetState();
}

class _StageAdvanceSheetState extends State<StageAdvanceSheet> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<_Check> _checksFor(LeadStage next) {
    final lead = widget.lead;
    if (lead == null) return const [];
    switch (next) {
      case LeadStage.profiling:
        // Lead → Profiling: need at least one logged activity
        return [
          _Check(
            label: 'At least one logged activity (call/meeting)',
            passed: lead.recentActivities
                .any((a) => !a.isSystemGenerated),
          ),
        ];
      case LeadStage.engage:
        // Profiling → Engage: need profiling research done + AUM estimate
        return [
          _Check(
            label: 'Profiling research completed',
            passed: lead.profiling != null ||
                lead.recentActivities.length > 2,
          ),
          _Check(
            label: 'AUM estimate captured',
            passed: lead.estimatedAum != null,
          ),
        ];
      case LeadStage.onboard:
        // Engage → Onboard: need a meeting logged + interested outcome
        return [
          _Check(
            label: 'At least one meeting logged',
            passed: lead.recentActivities.any((a) =>
                a.type.label == 'Meeting'),
          ),
          _Check(
            label: 'An interested or connected outcome',
            passed: lead.recentActivities.any((a) =>
                a.outcome != null &&
                (a.outcome!.label == 'Connected' ||
                    a.outcome!.label == 'Interested')),
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.currentStage.nextStage;
    if (next == null) return const SizedBox.shrink();

    final checks = _checksFor(next);
    final allPassed = checks.every((c) => c.passed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual progression
        Row(
          children: [
            _stageChip(widget.currentStage),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 18, color: AppColors.textHint),
            ),
            _stageChip(next, isNext: true),
          ],
        ),
        const SizedBox(height: 16),

        if (checks.isNotEmpty) ...[
          Text('Requirements', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          ...checks.map((c) => _checkRow(c)),
          const SizedBox(height: 12),
        ],

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.tealAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.tealAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.tealAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _guidance(next),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.tealAccent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CompassTextField(
          controller: _notesController,
          label: 'Notes (optional)',
          hint: 'Add context for this stage change…',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        CompassButton(
          label: 'Move to ${next.label}',
          onPressed: allPassed
              ? () {
                  widget.onAdvance(
                    next,
                    _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                  );
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }

  Widget _stageChip(LeadStage stage, {bool isNext = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: isNext ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: stage.color.withValues(alpha: isNext ? 0.5 : 0.2),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Text(
        stage.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: stage.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _checkRow(_Check c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            c.passed ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: c.passed ? AppColors.successGreen : AppColors.errorRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: c.passed ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _guidance(LeadStage next) {
    switch (next) {
      case LeadStage.profiling:
        return 'Research the prospect — profile their needs and prepare talking points.';
      case LeadStage.engage:
        return 'Schedule meetings and calls now that you understand the prospect.';
      case LeadStage.onboard:
        return 'Initiate account opening. This triggers the approval workflow.';
      default:
        return 'Confirm the stage change below.';
    }
  }
}

class _Check {
  final String label;
  final bool passed;
  const _Check({required this.label, required this.passed});
}
