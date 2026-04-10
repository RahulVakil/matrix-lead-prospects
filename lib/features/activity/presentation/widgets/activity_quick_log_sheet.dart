import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/models/next_action_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Bottom sheet to log a tactical activity (call/meeting/note/whatsapp).
/// Includes a NEW "Next action" chip row that wires through `setNextAction`.
/// After a Meeting log, prompts the RM whether an IB opportunity came up.
class ActivityQuickLogSheet extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String? companyName;
  final ActivityType? preselectedType;
  final void Function(
    ActivityType type,
    String? notes,
    ActivityOutcome? outcome,
    int? durationMinutes,
  ) onSave;

  const ActivityQuickLogSheet({
    super.key,
    required this.leadId,
    required this.leadName,
    this.companyName,
    this.preselectedType,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String leadId,
    required String leadName,
    String? companyName,
    ActivityType? preselectedType,
    required void Function(
      ActivityType type,
      String? notes,
      ActivityOutcome? outcome,
      int? durationMinutes,
    ) onSave,
  }) {
    return showCompassSheet(
      context,
      title: 'Log activity',
      child: ActivityQuickLogSheet(
        leadId: leadId,
        leadName: leadName,
        companyName: companyName,
        preselectedType: preselectedType,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ActivityQuickLogSheet> createState() => _ActivityQuickLogSheetState();
}

class _ActivityQuickLogSheetState extends State<ActivityQuickLogSheet> {
  late ActivityType _type;
  ActivityOutcome? _outcome;
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();

  NextActionType? _nextActionType;
  DateTime? _nextActionDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.preselectedType ?? ActivityType.call;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final duration = int.tryParse(_durationController.text);

    widget.onSave(_type, notes, _outcome, duration);

    // Persist next action if set
    if (_nextActionType != null && _nextActionType != NextActionType.none) {
      await getIt<LeadRepository>().setNextAction(
        widget.leadId,
        NextActionModel(
          type: _nextActionType!,
          dueAt: _nextActionDate,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    // After meeting → prompt for IB opportunity
    if (_type == ActivityType.meeting) {
      // ignore: use_build_context_synchronously
      _promptIbOpportunity(context);
    }
  }

  Future<void> _promptIbOpportunity(BuildContext context) async {
    final go = await showCompassSheet<bool>(
      context,
      title: 'Did any IB opportunity come up?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "If the meeting surfaced an Investment Banking deal opportunity, capture it now while it's fresh. Branch Head will review before it reaches the IB team.",
              style: AppTextStyles.bodyMedium,
            ),
          ),
          CompassButton(
            label: 'Yes — capture IB lead',
            icon: Icons.business_center,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          CompassButton.tertiary(
            label: 'No, not now',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );

    if (go == true && context.mounted) {
      context.push(
        '/ib-leads/new',
        extra: {
          'clientName': widget.leadName,
          'companyName': widget.companyName,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadName, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),

        // Type cards
        Row(
          children: [
            for (final t in [
              ActivityType.call,
              ActivityType.meeting,
              ActivityType.note,
              ActivityType.whatsApp,
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _typeCard(t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_type == ActivityType.call || _type == ActivityType.meeting) ...[
          Text('Outcome', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActivityOutcome.connected,
              ActivityOutcome.noAnswer,
              ActivityOutcome.interested,
              ActivityOutcome.followUp,
              ActivityOutcome.notInterested,
            ]
                .map(
                  (o) => CompassChoiceChip<ActivityOutcome>(
                    value: o,
                    groupValue: _outcome,
                    label: o.label,
                    onSelected: (v) => setState(() => _outcome = v),
                    color: o.isPositive ? AppColors.successGreen : AppColors.errorRed,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          CompassTextField(
            controller: _durationController,
            label: 'Duration (minutes)',
            hint: 'e.g. 15',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
        ],

        CompassTextField(
          controller: _notesController,
          label: 'Notes',
          hint: 'Brief summary of the interaction…',
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 16),

        Text('Next action', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NextActionType.values
              .map(
                (n) => CompassChoiceChip<NextActionType>(
                  value: n,
                  groupValue: _nextActionType,
                  label: n.label,
                  icon: n.icon,
                  onSelected: (v) => setState(() => _nextActionType = v),
                ),
              )
              .toList(),
        ),
        if (_nextActionType != null && _nextActionType != NextActionType.none) ...[
          const SizedBox(height: 12),
          CompassDateField(
            label: 'When',
            value: _nextActionDate,
            onChanged: (v) => setState(() => _nextActionDate = v),
            firstDate: DateTime.now(),
            showTime: true,
          ),
        ],

        const SizedBox(height: 20),
        CompassButton(
          label: 'Log ${_type.label}',
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _typeCard(ActivityType t) {
    final selected = _type == t;
    return InkWell(
      onTap: () => setState(() => _type = t),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyPrimary.withValues(alpha: 0.10)
              : AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.navyPrimary : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              t.icon,
              size: 22,
              color: selected ? AppColors.navyPrimary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              t.label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.navyPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
