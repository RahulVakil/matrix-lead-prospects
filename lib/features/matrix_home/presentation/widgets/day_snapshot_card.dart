import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/day_snapshot_data.dart';
import '../../data/home_calendar_store.dart';

/// Day Snapshot — calendar-aware home card. Adapts content to the selected
/// date: past = retrospective wrap-up; today = live counters; future =
/// scheduled work. CTA opens the per-day activity timeline.
class DaySnapshotCard extends StatelessWidget {
  const DaySnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeCalendarStore.instance,
      builder: (context, _) {
        final store = HomeCalendarStore.instance;
        final date = store.selectedDate;
        final snapshot = DaySnapshotData.forDate(date);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(date: date, store: store),
              const SizedBox(height: 14),
              if (snapshot.isEmpty)
                _emptyState()
              else if (store.isFuture)
                _futureBody(snapshot)
              else
                _pastOrTodayBody(snapshot, isToday: store.isToday),
              const SizedBox(height: 14),
              _CtaButton(
                label: store.isFuture
                    ? "View day's plan →"
                    : "View day's activity →",
                onTap: () => context.push(
                  '/day/${DateFormat('yyyy-MM-dd').format(date)}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'No activity on this day.',
        style: GoogleFonts.roboto(
          color: AppColors.textHint,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _pastOrTodayBody(DaySnapshot s, {required bool isToday}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(
          number: s.activitiesLogged,
          label: 'Activities logged',
          subtitle: _activityBreakdown(s),
        ),
        const SizedBox(height: 12),
        _StatRow(
          number: s.leadsCaptured,
          label: 'New leads captured',
        ),
        if (s.stageMoves > 0) ...[
          const SizedBox(height: 12),
          _StatRow(
            number: s.stageMoves,
            label: 'Pipeline moves',
            subtitle: s.stageMovesBreakdown.join(' · '),
          ),
        ],
      ],
    );
  }

  Widget _futureBody(DaySnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.scheduledFollowUps > 0)
          _StatRow(
            number: s.scheduledFollowUps,
            label: 'Follow-ups scheduled',
          ),
        if (s.scheduledMeetings > 0) ...[
          if (s.scheduledFollowUps > 0) const SizedBox(height: 12),
          _StatRow(
            number: s.scheduledMeetings,
            label: 'Meeting${s.scheduledMeetings == 1 ? '' : 's'}',
          ),
        ],
      ],
    );
  }

  String? _activityBreakdown(DaySnapshot s) {
    final parts = <String>[];
    if (s.callsLogged > 0) {
      parts.add('${s.callsLogged} call${s.callsLogged == 1 ? '' : 's'}');
    }
    if (s.meetingsLogged > 0) {
      parts.add(
          '${s.meetingsLogged} meeting${s.meetingsLogged == 1 ? '' : 's'}');
    }
    if (s.emailsLogged > 0) {
      parts.add('${s.emailsLogged} email${s.emailsLogged == 1 ? '' : 's'}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _Header extends StatelessWidget {
  final DateTime date;
  final HomeCalendarStore store;
  const _Header({required this.date, required this.store});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM').format(date);
    final String prefix;
    final String mode;
    if (store.isToday) {
      prefix = 'Today';
      mode = 'Live snapshot';
    } else if (store.isPast) {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final isYesterday = date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day;
      prefix = isYesterday ? 'Yesterday' : dateLabel;
      mode = 'Wrap-up';
    } else {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final isTomorrow = date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day;
      prefix = isTomorrow ? 'Tomorrow' : dateLabel;
      mode = 'Scheduled';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day snapshot',
                style: GoogleFonts.roboto(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                store.isToday
                    ? '$prefix, $dateLabel'
                    : (prefix == dateLabel ? prefix : '$prefix, $dateLabel'),
                style: GoogleFonts.roboto(
                  color: const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceTertiary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            mode,
            style: GoogleFonts.roboto(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final int number;
  final String label;
  final String? subtitle;
  const _StatRow({
    required this.number,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            number.toString().padLeft(2, '0'),
            style: GoogleFonts.roboto(
              color: AppColors.navyPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.roboto(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.roboto(
            color: AppColors.navyPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
