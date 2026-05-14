import 'package:flutter/material.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';

enum MeetingMode { online, inPerson }

class MeetingCreateResult {
  final String title;
  final DateTime when;
  final int durationMinutes;
  final MeetingMode mode;
  final String? meetingLink; // null when in-person
  final String? location;    // null when online
  final String? notes;
  final NextActionType? nextActionType;
  final DateTime? nextActionDate;

  const MeetingCreateResult({
    required this.title,
    required this.when,
    required this.durationMinutes,
    required this.mode,
    this.meetingLink,
    this.location,
    this.notes,
    required this.nextActionType,
    required this.nextActionDate,
  });

  /// Concise summary written into the activity-log notes field.
  String toLogNotes() {
    final lines = <String>[];
    lines.add(title);
    final modeLabel = mode == MeetingMode.online ? 'Online' : 'In-person';
    lines.add('$modeLabel · ${durationMinutes}m');
    if (mode == MeetingMode.online && meetingLink != null && meetingLink!.isNotEmpty) {
      lines.add('Link: $meetingLink');
    }
    if (mode == MeetingMode.inPerson && location != null && location!.isNotEmpty) {
      lines.add('Where: $location');
    }
    if (notes != null && notes!.isNotEmpty) {
      lines.add(notes!);
    }
    return lines.join('\n');
  }
}

/// Bottom sheet for creating a meeting with a lead.
///
/// Captures title, when, duration, mode (online/in-person), link/location,
/// notes, and an optional next action. Returns a [MeetingCreateResult] for
/// the caller to log the activity and set the next action.
///
/// When opened as a chained "follow-up meeting" from another sheet, pass
/// [prefilledWhen] to prefill the date and [hideNextAction] to suppress the
/// next-action picker (the parent sheet has already collected it).
class MeetingCreateSheet {
  static Future<MeetingCreateResult?> show(
    BuildContext context, {
    required String leadName,
    DateTime? prefilledWhen,
    bool hideNextAction = false,
  }) {
    final isFollowUp = prefilledWhen != null && hideNextAction;
    return showCompassSheet<MeetingCreateResult>(
      context,
      title: isFollowUp
          ? 'Set up the follow-up meeting'
          : 'Schedule meeting with $leadName',
      child: _Body(
        leadName: leadName,
        prefilledWhen: prefilledWhen,
        hideNextAction: hideNextAction,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final String leadName;
  final DateTime? prefilledWhen;
  final bool hideNextAction;
  const _Body({
    required this.leadName,
    this.prefilledWhen,
    this.hideNextAction = false,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _notesCtrl = TextEditingController();

  DateTime? _when;
  MeetingMode _mode = MeetingMode.online;
  NextActionType? _nextActionType;
  DateTime? _nextActionDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _when = widget.prefilledWhen;
    _titleCtrl.addListener(() => setState(() {}));
    _linkCtrl.addListener(() => setState(() {}));
    _locationCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_when == null) return false;
    final duration = int.tryParse(_durationCtrl.text);
    if (duration == null || duration <= 0) return false;
    if (_mode == MeetingMode.online && _linkCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final result = MeetingCreateResult(
      title: _titleCtrl.text.trim(),
      when: _when!,
      durationMinutes: int.parse(_durationCtrl.text),
      mode: _mode,
      meetingLink: _mode == MeetingMode.online ? _linkCtrl.text.trim() : null,
      location: _mode == MeetingMode.inPerson ? _locationCtrl.text.trim() : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      nextActionType: _nextActionType,
      nextActionDate: _nextActionDate,
    );
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadName, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),

        CompassTextField(
          controller: _titleCtrl,
          label: 'Title',
          isRequired: true,
          hint: 'e.g. Quarterly portfolio review',
          maxLength: 120,
        ),
        const SizedBox(height: 12),

        CompassDateField(
          label: 'When',
          value: _when,
          onChanged: (v) => setState(() => _when = v),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          showTime: true,
        ),
        const SizedBox(height: 12),

        CompassTextField(
          controller: _durationCtrl,
          label: 'Duration (minutes)',
          hint: 'e.g. 30',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),

        Text('Mode', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _modeCard(
                MeetingMode.online,
                Icons.videocam_outlined,
                'Online',
                'Teams / Zoom / Meet',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeCard(
                MeetingMode.inPerson,
                Icons.location_on_outlined,
                'In-person',
                'Branch / client office',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_mode == MeetingMode.online)
          CompassTextField(
            controller: _linkCtrl,
            label: 'Meeting link',
            isRequired: true,
            hint: 'Paste Teams / Zoom / Meet link',
            prefixIcon: Icons.link,
            maxLength: 500,
          )
        else
          CompassTextField(
            controller: _locationCtrl,
            label: 'Location',
            hint: 'e.g. JM Financial, BKC office',
            prefixIcon: Icons.location_on_outlined,
            maxLength: 200,
          ),
        const SizedBox(height: 12),

        CompassTextField(
          controller: _notesCtrl,
          label: 'Notes (optional)',
          hint: 'Agenda or things to remember…',
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 16),

        if (!widget.hideNextAction) ...[
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
        ],

        const SizedBox(height: 20),
        CompassButton(
          label: 'Schedule meeting',
          icon: Icons.event_available,
          isLoading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }

  Widget _modeCard(MeetingMode mode, IconData icon, String label, String sub) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
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
                      color: selected ? AppColors.navyPrimary : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    sub,
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
