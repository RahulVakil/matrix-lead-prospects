import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_top_bar.dart';
import '../../../matrix_home/data/day_snapshot_data.dart';

/// Drill-down for the Day Snapshot CTA. Shows the timeline of activities,
/// new leads, pipeline moves, and scheduled work for the selected date.
/// Production: backed by an activity-log query filtered by RM + date.
class DayActivityScreen extends StatelessWidget {
  final String dateString; // YYYY-MM-DD
  const DayActivityScreen({super.key, required this.dateString});

  DateTime? get _date {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(dateString);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _date;
    if (date == null) {
      return Scaffold(
        backgroundColor: AppColors.heroBackdrop,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const HeaderTopBar(title: 'Day activity'),
              Expanded(
                child: Center(
                  child: Text(
                    'Invalid date',
                    style: GoogleFonts.roboto(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final picked = DateTime(date.year, date.month, date.day);
    final offset = picked.difference(today).inDays;
    final mode = offset == 0
        ? 'Today'
        : (offset == -1
            ? 'Yesterday'
            : (offset == 1 ? 'Tomorrow' : DateFormat('EEEE').format(date)));
    final niceDate = DateFormat('d MMM yyyy').format(date);
    final snapshot = DaySnapshotData.forDate(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            HeaderTopBar(title: '$mode · $niceDate'),
            Expanded(
              child: snapshot.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: _sections(snapshot, isFuture: offset > 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTertiary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_outlined,
                    color: AppColors.textMuted, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'No activity on this day',
                style: GoogleFonts.roboto(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> _sections(DaySnapshot s, {required bool isFuture}) {
    final widgets = <Widget>[];
    if (!isFuture) {
      if (s.activitiesLogged > 0) {
        widgets.add(_SectionCard(
          title: 'Activities logged',
          count: s.activitiesLogged,
          children: [
            if (s.callsLogged > 0)
              _Bullet(
                  icon: Icons.phone_outlined,
                  text: '${s.callsLogged} call${s.callsLogged == 1 ? '' : 's'}'),
            if (s.meetingsLogged > 0)
              _Bullet(
                  icon: Icons.event_outlined,
                  text:
                      '${s.meetingsLogged} meeting${s.meetingsLogged == 1 ? '' : 's'}'),
            if (s.emailsLogged > 0)
              _Bullet(
                  icon: Icons.email_outlined,
                  text:
                      '${s.emailsLogged} email${s.emailsLogged == 1 ? '' : 's'}'),
          ],
        ));
        widgets.add(const SizedBox(height: 14));
      }
      if (s.leadsCaptured > 0) {
        widgets.add(_SectionCard(
          title: 'New leads captured',
          count: s.leadsCaptured,
          children: const [
            _Bullet(
                icon: Icons.person_add_alt_1_outlined,
                text: 'Captured via FAB / Get-lead pool'),
          ],
        ));
        widgets.add(const SizedBox(height: 14));
      }
      if (s.stageMoves > 0) {
        widgets.add(_SectionCard(
          title: 'Pipeline moves',
          count: s.stageMoves,
          children: s.stageMovesBreakdown
              .map((b) => _Bullet(icon: Icons.trending_up, text: b))
              .toList(),
        ));
      }
    } else {
      if (s.scheduledFollowUps > 0) {
        widgets.add(_SectionCard(
          title: 'Follow-ups scheduled',
          count: s.scheduledFollowUps,
          children: const [
            _Bullet(
                icon: Icons.event_repeat_outlined,
                text: 'See follow-ups list for details'),
          ],
        ));
        widgets.add(const SizedBox(height: 14));
      }
      if (s.scheduledMeetings > 0) {
        widgets.add(_SectionCard(
          title: 'Meetings',
          count: s.scheduledMeetings,
          children: const [
            _Bullet(
                icon: Icons.calendar_today_outlined,
                text: 'See Meetings section on home for details'),
          ],
        ));
      }
    }
    return widgets;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString().padLeft(2, '0'),
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                color: const Color(0xFF394150),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
