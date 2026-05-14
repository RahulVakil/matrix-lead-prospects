import 'package:flutter/material.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';

/// Result of the meeting picker sheet.
sealed class MeetingPickResult {
  const MeetingPickResult();
}

/// RM picked an existing scheduled meeting and wants to LOG it (mark held).
class MeetingPickLog extends MeetingPickResult {
  final ActivityModel meeting;
  const MeetingPickLog(this.meeting);
}

/// RM picked a scheduled meeting and wants to CANCEL it (no log entry).
class MeetingPickCancel extends MeetingPickResult {
  final ActivityModel meeting;
  const MeetingPickCancel(this.meeting);
}

/// RM had a walk-in / ad-hoc meeting that wasn't scheduled — fall back to
/// creating a fresh log entry.
class MeetingPickAdHoc extends MeetingPickResult {
  const MeetingPickAdHoc();
}

/// Bottom sheet shown when the RM picks "Log a past meeting" from the
/// Meet chooser. Lists scheduled meetings on this lead that haven't been
/// logged yet (i.e. `outcome = followUp`). Lets the RM either pick one
/// to log against, cancel a scheduled meeting, or fall back to a
/// walk-in / ad-hoc record.
class MeetingPickerSheet {
  static Future<MeetingPickResult?> show(
    BuildContext context, {
    required String leadName,
    required List<ActivityModel> scheduledMeetings,
  }) {
    return showCompassSheet<MeetingPickResult>(
      context,
      title: 'Which meeting?',
      child: _Body(
        leadName: leadName,
        scheduledMeetings: scheduledMeetings,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String leadName;
  final List<ActivityModel> scheduledMeetings;
  const _Body({required this.leadName, required this.scheduledMeetings});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pick the meeting you want to log against $leadName, or capture it as a walk-in if it wasn\'t scheduled.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),

        if (scheduledMeetings.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No scheduled meetings on this lead yet.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...scheduledMeetings.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MeetingRow(
                meeting: m,
                onLog: () =>
                    Navigator.of(context).pop(MeetingPickLog(m)),
                onCancel: () =>
                    Navigator.of(context).pop(MeetingPickCancel(m)),
              ),
            ),
          ),

        const SizedBox(height: 6),
        Divider(color: AppColors.borderDefault.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        CompassButton.tertiary(
          label: 'It wasn\'t a scheduled meeting',
          icon: Icons.directions_walk,
          onPressed: () =>
              Navigator.of(context).pop(const MeetingPickAdHoc()),
        ),
      ],
    );
  }
}

class _MeetingRow extends StatelessWidget {
  final ActivityModel meeting;
  final VoidCallback onLog;
  final VoidCallback onCancel;
  const _MeetingRow({
    required this.meeting,
    required this.onLog,
    required this.onCancel,
  });

  String get _title {
    final notes = meeting.notes ?? '';
    final firstLine = notes.split('\n').first.trim();
    return firstLine.isEmpty ? 'Meeting' : firstLine;
  }

  String get _subtitle {
    final mins = meeting.durationMinutes ?? 0;
    final dur = mins == 0 ? '' : ' · ${mins}m';
    // Pull the second line of notes (mode + duration label) if present;
    // otherwise just show date/time.
    final notes = meeting.notes ?? '';
    final lines = notes.split('\n');
    final modeLine = lines.length > 1 ? lines[1].trim() : '';
    final dateText =
        '${meeting.dateDisplay} · ${meeting.timeDisplay}$dur';
    return modeLine.isEmpty ? dateText : '$dateText · $modeLine';
  }

  String get _ageHint {
    final now = DateTime.now();
    final diff = meeting.dateTime.difference(now);
    if (diff.isNegative) {
      final days = -diff.inDays;
      if (days == 0) return 'Earlier today — pending log';
      if (days == 1) return 'Yesterday — pending log';
      return '$days days ago — pending log';
    } else {
      final days = diff.inDays;
      if (days == 0) return 'Later today';
      if (days == 1) return 'Tomorrow';
      return 'in $days days';
    }
  }

  Color get _ageColor {
    final overdue = meeting.dateTime.isBefore(DateTime.now());
    return overdue ? AppColors.warmAmber : AppColors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onLog,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event,
                    size: 18, color: AppColors.navyPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _ageColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _ageHint,
                        style: AppTextStyles.caption.copyWith(
                          color: _ageColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cancel this meeting',
                icon: const Icon(Icons.close),
                color: AppColors.textHint,
                iconSize: 18,
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation sheet shown when the RM hits the X on a scheduled meeting.
/// Returns true if the user confirmed cancellation.
Future<bool> showCancelMeetingConfirm(
  BuildContext context, {
  required String meetingTitle,
}) async {
  final confirmed = await showCompassSheet<bool>(
    context,
    title: 'Cancel meeting?',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '"$meetingTitle" will be marked cancelled and stop appearing in upcoming meetings. The activity stays in the timeline so the cancellation is auditable.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        CompassButton(
          label: 'Cancel meeting',
          icon: Icons.event_busy_outlined,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        CompassButton.tertiary(
          label: 'Keep it',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Builds the title-prefix that the activity log sheet should show when
/// logging an existing scheduled meeting (so the RM knows which one).
String formatMeetingContext(ActivityModel m) {
  final notes = m.notes ?? '';
  final firstLine = notes.split('\n').first.trim();
  final title = firstLine.isEmpty ? 'Meeting' : firstLine;
  return 'Logging: $title (${m.dateDisplay} · ${m.timeDisplay})';
}

/// Filter helper — returns scheduled meetings on a lead (those with
/// `outcome = followUp`). Sorted: most-recent past first (overdue logs
/// at the top), then upcoming.
List<ActivityModel> selectScheduledMeetings(
    Iterable<ActivityModel> activities) {
  final now = DateTime.now();
  final scheduled = activities
      .where((a) =>
          a.type == ActivityType.meeting &&
          a.outcome == ActivityOutcome.followUp)
      .toList();
  scheduled.sort((a, b) {
    final aPast = a.dateTime.isBefore(now);
    final bPast = b.dateTime.isBefore(now);
    if (aPast != bPast) return aPast ? -1 : 1; // past first
    if (aPast) {
      return b.dateTime.compareTo(a.dateTime); // most recent past first
    } else {
      return a.dateTime.compareTo(b.dateTime); // soonest upcoming first
    }
  });
  return scheduled;
}
