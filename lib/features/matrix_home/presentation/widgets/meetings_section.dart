import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';
import '../../../meetings/data/meeting_draft_store.dart';
import '../../../meetings/data/mock_meetings.dart';
import '../../../meetings/domain/meeting_model.dart';
import '../../data/home_calendar_store.dart';

/// Meetings section on home — mirrors compass_v2_mobile/_buildMeetingsSection
/// (home_dashboard_content.dart:697). Behaviour:
///   - Tap a card → /meetings/:id (full detail with Log + Join/Start)
///   - Start/Join button → snackbar (production: opens Teams URL or marks
///     in-person meeting started)
///   - "Draft" amber pill appears on a card whenever the user has saved
///     an unsubmitted log draft for that meeting (live-binds to
///     [MeetingDraftStore])
class MeetingsSection extends StatelessWidget {
  const MeetingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeCalendarStore.instance,
      builder: (context, _) {
        final selected = HomeCalendarStore.instance.selectedDate;
        // Filter mock meetings by date+month string match (prototype fidelity).
        final mDay = selected.day.toString().padLeft(2, '0');
        final mMonth = _shortMonth(selected.month);
        final meetings = MockMeetings.all
            .where((m) => m.date == mDay && m.month == mMonth)
            .toList();
        return _buildBody(context, meetings);
      },
    );
  }

  String _shortMonth(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m];
  }

  Widget _buildBody(BuildContext context, List<MeetingModel> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Meetings',
              style: GoogleFonts.roboto(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                meetings.length.toString().padLeft(2, '0'),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.push(RouteNames.meetings),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Show all',
                      style: GoogleFonts.roboto(
                        color: AppColors.navyPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.navyPrimary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (meetings.isEmpty)
          _EmptyMeetings()
        else
          ListenableBuilder(
            listenable: MeetingDraftStore.instance,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: List.generate(meetings.length, (i) {
                  final m = meetings[i];
                  final isLast = i == meetings.length - 1;
                  final hasDraft =
                      MeetingDraftStore.instance.hasDraft(m.id);
                  return Column(
                    children: [
                      _MeetingRow(meeting: m, hasDraft: hasDraft),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

}

class _EmptyMeetings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_available_outlined,
                size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No meetings on this day',
              style: GoogleFonts.roboto(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  final MeetingModel meeting;
  final bool hasDraft;
  const _MeetingRow({required this.meeting, required this.hasDraft});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(RouteNames.meetingDetailPath(meeting.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFF4F9FD),
                  ),
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Center(
                    child: Text(
                      meeting.date,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ),
                Text(
                  meeting.month,
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF91929E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          meeting.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF0A1629),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (meeting.isHighPriority) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'H',
                            style: GoogleFonts.roboto(
                              color: AppColors.navyPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (hasDraft) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.warmAmber
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark,
                                  size: 10, color: AppColors.warmAmber),
                              const SizedBox(width: 3),
                              Text(
                                'Draft',
                                style: GoogleFonts.roboto(
                                  color: AppColors.warmAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        meeting.isVideo
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        size: 14,
                        color: const Color(0xFF767676),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          meeting.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF767676),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meeting.time,
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF767676),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (meeting.canStart)
              OutlinedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      meeting.isVideo
                          ? 'Joining ${meeting.name} (Teams)'
                          : 'Starting ${meeting.name}',
                    ),
                    duration: const Duration(milliseconds: 1200),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                icon: Icon(
                  meeting.isVideo
                      ? Icons.videocam
                      : Icons.play_arrow_rounded,
                  size: 16,
                ),
                label: Text(
                  meeting.isVideo ? 'Join' : 'Start',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  side: const BorderSide(color: Color(0xFFD1D2D9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
