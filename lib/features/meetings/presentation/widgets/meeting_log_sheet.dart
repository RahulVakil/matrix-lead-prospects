import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../data/meeting_draft_store.dart';
import '../../domain/meeting_model.dart';

/// Bottom sheet to log a meeting outcome. Mirrors the lead-module's
/// `ActivityQuickLogSheet` field-by-field (outcome chips, duration, mode
/// in-person/video, link/location, notes, next-action chips, next-action
/// date) so the RM has one consistent log surface across the app.
///
/// **Adds draft support** on top of the lead-module sheet:
///   - On open, prefills from `MeetingDraftStore` if a draft exists
///   - "Save as draft" button persists current state and closes
///   - "Log meeting" submits, clears the draft, and closes
///   - A "Resumed from draft" hint appears at the top when a draft loaded
class MeetingLogSheet {
  static Future<void> show(
    BuildContext context, {
    required MeetingModel meeting,
    required VoidCallback onLogged,
  }) {
    return showCompassSheet(
      context,
      title: 'Log meeting',
      child: _Body(meeting: meeting, onLogged: onLogged),
    );
  }
}

class _Body extends StatefulWidget {
  final MeetingModel meeting;
  final VoidCallback onLogged;

  const _Body({required this.meeting, required this.onLogged});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  ActivityOutcome? _outcome;
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();

  bool _meetingIsOnline = true;
  final _meetingLinkController = TextEditingController();
  final _meetingLocationController = TextEditingController();

  NextActionType? _nextActionType;
  DateTime? _nextActionDate;

  bool _resumedFromDraft = false;
  bool _savingDraft = false;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    _meetingIsOnline = widget.meeting.isVideo;
    _hydrateFromDraft();
  }

  void _hydrateFromDraft() {
    final draft = MeetingDraftStore.instance.getDraft(widget.meeting.id);
    if (draft == null) return;
    setState(() {
      _resumedFromDraft = true;
      _outcome = draft.outcome;
      _durationController.text =
          draft.durationMinutes?.toString() ?? '';
      _meetingIsOnline = draft.meetingIsOnline;
      _meetingLinkController.text = draft.meetingLink;
      _meetingLocationController.text = draft.meetingLocation;
      _notesController.text = draft.notes;
      _nextActionType = draft.nextActionType;
      _nextActionDate = draft.nextActionDate;
    });
  }

  MeetingDraft _captureDraft() => MeetingDraft(
        outcome: _outcome,
        durationMinutes: int.tryParse(_durationController.text),
        meetingIsOnline: _meetingIsOnline,
        meetingLink: _meetingLinkController.text,
        meetingLocation: _meetingLocationController.text,
        notes: _notesController.text,
        nextActionType: _nextActionType,
        nextActionDate: _nextActionDate,
        updatedAt: DateTime.now(),
      );

  Future<void> _saveDraft() async {
    setState(() => _savingDraft = true);
    MeetingDraftStore.instance.save(widget.meeting.id, _captureDraft());
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved — resume any time from the meeting card'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _log() async {
    setState(() => _logging = true);
    // In production: call activity-log API + chain next-action create if set
    // (e.g. open MeetingCreateSheet when next action is "meeting").
    MeetingDraftStore.instance.clear(widget.meeting.id);
    widget.onLogged();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meeting with ${widget.meeting.name} logged'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    _meetingLinkController.dispose();
    _meetingLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_resumedFromDraft) _ResumedFromDraftBanner(),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today,
                  size: 18, color: AppColors.navyPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.meeting.name, style: AppTextStyles.bodySmall),
                  Text(
                    '${widget.meeting.date} ${widget.meeting.month} · ${widget.meeting.time}',
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

        Text('Outcome', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            ActivityOutcome.connected,
            ActivityOutcome.noAnswer,
            ActivityOutcome.interested,
            ActivityOutcome.followUp,
            ActivityOutcome.notInterested,
          ]
              .map((o) => CompassChoiceChip<ActivityOutcome>(
                    value: o,
                    groupValue: _outcome,
                    label: o.label,
                    onSelected: (v) => setState(() => _outcome = v),
                    color: o.isPositive
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        CompassTextField(
          controller: _durationController,
          label: 'Duration (minutes)',
          hint: 'e.g. 30',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

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
              .map((n) => CompassChoiceChip<NextActionType>(
                    value: n,
                    groupValue: _nextActionType,
                    label: n.label,
                    icon: n.icon,
                    onSelected: (v) => setState(() => _nextActionType = v),
                  ))
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
        Row(
          children: [
            Expanded(
              child: CompassButton.secondary(
                label: 'Save as draft',
                icon: Icons.bookmark_border,
                isLoading: _savingDraft,
                onPressed: _saveDraft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CompassButton(
                label: 'Log meeting',
                isLoading: _logging,
                onPressed: _log,
              ),
            ),
          ],
        ),
      ],
    );
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
            Icon(icon,
                size: 22,
                color:
                    selected ? AppColors.navyPrimary : AppColors.textSecondary),
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
}

class _ResumedFromDraftBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warmAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark, size: 16, color: AppColors.warmAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resumed from draft. Edit and Log meeting when ready.',
              style: GoogleFonts.roboto(
                color: const Color(0xFF8A4F00),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
