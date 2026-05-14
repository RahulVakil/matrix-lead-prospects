import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_top_bar.dart';
import '../../../../routing/route_names.dart';
import '../../data/meeting_draft_store.dart';
import '../../data/mock_meetings.dart';
import '../../domain/meeting_model.dart';

/// Show-All Meetings list — mirrors compass_v2_mobile/MeetingsDetailsView.
/// Header: navy HeaderTopBar with "Meetings" title.
/// Top actions row: 3 icon tiles (Create Meet · Clients Near Me · Log Meet).
/// Pill-style tab switcher: Upcoming · Past.
/// Body: filtered meeting list per tab. Cards behave like home — Start/Join,
/// "Draft" pill, tap → meeting detail.
class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = [_MeetingTab.upcoming, _MeetingTab.past];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _index = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const HeaderTopBar(title: 'Meetings'),
            const _TopActionsRow(),
            _TabSwitcher(
              currentIndex: _index,
              onTabChanged: (i) {
                _tabController.animateTo(i);
                setState(() => _index = i);
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => _TabBody(tab: tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MeetingTab { upcoming, past }

class _TabBody extends StatelessWidget {
  final _MeetingTab tab;
  const _TabBody({required this.tab});

  @override
  Widget build(BuildContext context) {
    final meetings = tab == _MeetingTab.upcoming
        ? MockMeetings.upcoming()
        : MockMeetings.past();

    if (meetings.isEmpty) {
      return Center(
        child: Text(
          'No ${tab == _MeetingTab.upcoming ? 'upcoming' : 'past'} meetings',
          style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListenableBuilder(
      listenable: MeetingDraftStore.instance,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: meetings.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MeetingCard(meeting: meetings[i]),
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _TabSwitcher({
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            _tab('Upcoming', 0),
            _tab('Past', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          height: 55,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? AppColors.navyPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: selected ? Colors.white : const Color(0xFF6C6969),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  const _TopActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionTile(
            icon: Icons.calendar_today_outlined,
            label: 'Create Meet',
            onTap: () => _comingSoon(context, 'Create Meeting'),
          ),
          _ActionTile(
            icon: Icons.location_searching_rounded,
            label: 'Clients Near Me',
            onTap: () => _comingSoon(context, 'Clients near me'),
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            label: 'Log Meet',
            onTap: () => _comingSoon(context, 'Log a meeting'),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — opens in production via the Meetings module'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            children: [
              Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE9EAEF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: AppColors.navyPrimary),
              ),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF41414E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final hasDraft = MeetingDraftStore.instance.hasDraft(meeting.id);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(RouteNames.meetingDetailPath(meeting.id)),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date column
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF4F9FD),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      meeting.date,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
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
                          _HBadge(),
                        ],
                        if (hasDraft) ...[
                          const SizedBox(width: 6),
                          _DraftPill(),
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
      ),
    );
  }
}

class _HBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
    );
  }
}

class _DraftPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: AppColors.warmAmber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark, size: 10, color: AppColors.warmAmber),
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
    );
  }
}
