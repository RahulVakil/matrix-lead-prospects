import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Bottom sheet to log a tactical activity (call/meeting/note/whatsapp).
/// The activity type is set by the caller (each outer CTA preselects its
/// own type) — there is intentionally no type-switcher here so the user
/// has a single, focused logging surface.
///
/// Captures notes, outcome, optional duration, and a follow-up next-action
/// chip + date. The caller is responsible for persisting the activity AND
/// the next action, so it can chain (e.g. open MeetingCreateSheet when the
/// follow-up is a meeting).
///
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
    NextActionType? nextActionType,
    DateTime? nextActionDate,
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
      NextActionType? nextActionType,
      DateTime? nextActionDate,
    ) onSave,
  }) {
    final t = preselectedType ?? ActivityType.call;
    return showCompassSheet(
      context,
      title: 'Log ${t.label.toLowerCase()}',
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

  // Meeting-only fields. The RM picks mode (Online video call vs
  // In-person) and optionally a link/location. We capture this for
  // every meeting log — both walk-ins and "log against scheduled"
  // — so the timeline reflects how the meeting actually happened,
  // independent of what was scheduled.
  bool _meetingIsOnline = true;
  final _meetingLinkController = TextEditingController();
  final _meetingLocationController = TextEditingController();

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
    _meetingLinkController.dispose();
    _meetingLocationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final rawNotes = _notesController.text.trim();
    final duration = int.tryParse(_durationController.text);

    // For meeting logs we prepend a one-line context (mode + link or
    // location) to the notes so the timeline shows how the meeting
    // actually happened. Walk-in / scheduled-log paths both flow
    // through here so this stays consistent.
    String? finalNotes;
    if (_type == ActivityType.meeting) {
      final modeLine = _meetingIsOnline
          ? (_meetingLinkController.text.trim().isEmpty
              ? 'Video call'
              : 'Video call · ${_meetingLinkController.text.trim()}')
          : (_meetingLocationController.text.trim().isEmpty
              ? 'In-person'
              : 'In-person · ${_meetingLocationController.text.trim()}');
      finalNotes = rawNotes.isEmpty ? modeLine : '$modeLine\n$rawNotes';
    } else {
      finalNotes = rawNotes.isEmpty ? null : rawNotes;
    }

    // Caller persists the activity AND the next action (so it can chain
    // a follow-up meeting create sheet when next-action is "meeting").
    widget.onSave(_type, finalNotes, _outcome, duration, _nextActionType, _nextActionDate);

    if (!mounted) return;
    Navigator.of(context).pop();

    // After meeting → prompt for IB opportunity
    if (_type == ActivityType.meeting) {
      // ignore: use_build_context_synchronously
      _promptIbOpportunity(context);
    }
  }

  Widget _modeCard({
    required bool isOnline,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final selected = _meetingIsOnline == isOnline;
    return InkWell(
      onTap: () => setState(() => _meetingIsOnline = isOnline),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.navyPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? AppColors.navyPrimary
                          : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_type.icon, size: 18, color: AppColors.navyPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.leadName, style: AppTextStyles.bodySmall),
                  Text(
                    _type.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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

        // Meeting-only: how was it conducted?
        if (_type == ActivityType.meeting) ...[
          Text('How was it conducted?', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _modeCard(
                  isOnline: false,
                  icon: Icons.location_on_outlined,
                  label: 'In-person',
                  subtitle: 'Branch / client office',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeCard(
                  isOnline: true,
                  icon: Icons.videocam_outlined,
                  label: 'Video call',
                  subtitle: 'Teams / Zoom / Meet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_meetingIsOnline)
            CompassTextField(
              controller: _meetingLinkController,
              label: 'Meeting link',
              hint: 'Optional — paste link if you have it',
              prefixIcon: Icons.link,
              maxLength: 500,
            )
          else
            CompassTextField(
              controller: _meetingLocationController,
              label: 'Location',
              hint: 'Optional — e.g. JM Financial, BKC office',
              prefixIcon: Icons.location_on_outlined,
              maxLength: 200,
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

        Text('Set a follow-up (optional)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            )),
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

}
