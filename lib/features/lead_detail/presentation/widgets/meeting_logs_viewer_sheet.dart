import 'package:flutter/material.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

/// Read-only sheet showing every meeting the RM has logged for this lead.
class MeetingLogsViewerSheet {
  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required List<ActivityModel> activities,
  }) {
    final meetings = activities
        .where((a) => a.type == ActivityType.meeting)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return showCompassSheet<void>(
      context,
      title: 'Meeting logs · $leadName',
      child: _Body(meetings: meetings),
    );
  }
}

class _Body extends StatelessWidget {
  final List<ActivityModel> meetings;
  const _Body({required this.meetings});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          meetings.isEmpty
              ? 'No meetings logged'
              : '${meetings.length} meeting${meetings.length == 1 ? '' : 's'} logged',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (meetings.isEmpty)
          _emptyState()
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MeetingRow(meeting: meetings[i]),
            ),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 20, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No meetings have been logged for this lead.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  final ActivityModel meeting;
  const _MeetingRow({required this.meeting});

  bool get _isVideo {
    final n = (meeting.notes ?? '').toLowerCase();
    return n.startsWith('video call');
  }

  @override
  Widget build(BuildContext context) {
    final outcomeColor = meeting.outcome == null
        ? AppColors.textHint
        : (meeting.outcome!.isPositive
            ? AppColors.successGreen
            : AppColors.errorRed);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
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
                child: Icon(
                  _isVideo
                      ? Icons.videocam_outlined
                      : Icons.event_outlined,
                  size: 16,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meeting.dateDisplay} · ${meeting.timeDisplay}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Logged by ${meeting.loggedByName}'
                      '${meeting.durationMinutes != null ? ' · ${meeting.durationDisplay}' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (meeting.outcome != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: outcomeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: outcomeColor.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    meeting.outcome!.label,
                    style: AppTextStyles.caption.copyWith(
                      color: outcomeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
            ],
          ),
          if (meeting.notes != null && meeting.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                meeting.notes!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF394150),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
