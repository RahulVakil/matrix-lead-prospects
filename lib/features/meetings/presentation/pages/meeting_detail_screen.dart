import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../data/meeting_draft_store.dart';
import '../../data/mock_meetings.dart';
import '../../domain/meeting_model.dart';
import '../widgets/meeting_log_sheet.dart';

/// Meeting detail. Reached from the home Meetings card tap.
/// Layout:
///   - Hero app bar with back arrow
///   - Date / time / mode summary
///   - Agenda card (pre-meeting notes, if any)
///   - Action buttons:
///       Join (video) or Start (in-person)  → opens calendar / Teams
///       **Log this meeting** primary CTA   → opens MeetingLogSheet
///   - "Draft saved" banner above CTA when MeetingDraftStore has a draft
class MeetingDetailScreen extends StatelessWidget {
  final String meetingId;
  const MeetingDetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final meeting = MockMeetings.byId(meetingId);
    if (meeting == null) {
      return HeroScaffold(
        header: HeroAppBar.simple(title: 'Meeting'),
        body: const Center(child: Text('Meeting not found')),
      );
    }

    return HeroScaffold(
      header: HeroAppBar.simple(
        title: meeting.name,
        subtitle: '${meeting.date} ${meeting.month} · ${meeting.time}',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _SummaryCard(meeting: meeting),
          if (meeting.agenda != null) ...[
            const SizedBox(height: 16),
            _AgendaCard(agenda: meeting.agenda!),
          ],
          const SizedBox(height: 24),
          _ActionsBlock(meeting: meeting),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MeetingModel meeting;
  const _SummaryCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  meeting.date,
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meeting.month,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color(0xFF91929E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meeting.name,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (meeting.isHighPriority) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      meeting.isVideo
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      size: 16,
                      color: const Color(0xFF767676),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        meeting.location,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF767676),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Color(0xFF767676)),
                    const SizedBox(width: 6),
                    Text(
                      meeting.time,
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF767676),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final String agenda;
  const _AgendaCard({required this.agenda});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_outlined,
                  size: 16, color: AppColors.navyPrimary),
              const SizedBox(width: 6),
              Text(
                'Agenda',
                style: GoogleFonts.roboto(
                  color: AppColors.navyPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            agenda,
            style: GoogleFonts.roboto(
              color: const Color(0xFF394150),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  final MeetingModel meeting;
  const _ActionsBlock({required this.meeting});

  @override
  Widget build(BuildContext context) {
    // Listen to draft store so the banner appears/disappears live as drafts
    // are saved or cleared from the log sheet.
    return ListenableBuilder(
      listenable: MeetingDraftStore.instance,
      builder: (context, _) {
        final hasDraft = MeetingDraftStore.instance.hasDraft(meeting.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Join / Start
            CompassButton.secondary(
              label: meeting.isVideo ? 'Join meeting' : 'Start meeting',
              icon: meeting.isVideo
                  ? Icons.videocam
                  : Icons.play_arrow_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
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
            ),
            const SizedBox(height: 18),
            if (hasDraft) const _DraftSavedBanner(),
            CompassButton(
              label: hasDraft ? 'Resume draft & log' : 'Log this meeting',
              icon: Icons.edit_note_rounded,
              onPressed: () => MeetingLogSheet.show(
                context,
                meeting: meeting,
                onLogged: () {},
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraftSavedBanner extends StatelessWidget {
  const _DraftSavedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.warmAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark,
              size: 16, color: AppColors.warmAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have a draft for this meeting. Tap below to resume.',
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
