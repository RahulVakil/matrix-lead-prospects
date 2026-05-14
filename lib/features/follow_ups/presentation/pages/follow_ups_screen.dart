import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';

/// Filter applied to the follow-ups list.
enum FollowUpFilter {
  overdue,
  today;

  String get title {
    switch (this) {
      case FollowUpFilter.overdue:
        return 'Follow-ups overdue';
      case FollowUpFilter.today:
        return 'Follow-ups due today';
    }
  }

  String get sectionLabel {
    switch (this) {
      case FollowUpFilter.overdue:
        return 'Overdue';
      case FollowUpFilter.today:
        return 'Due today';
    }
  }

  Color get accentColor {
    switch (this) {
      case FollowUpFilter.overdue:
        return AppColors.errorRed;
      case FollowUpFilter.today:
        return AppColors.warmAmber;
    }
  }

  String get emptyTitle {
    switch (this) {
      case FollowUpFilter.overdue:
        return 'No overdue follow-ups';
      case FollowUpFilter.today:
        return 'No follow-ups for today';
    }
  }
}

enum _FollowUpType {
  call('Call', Icons.phone_outlined),
  meeting('Meeting', Icons.event_outlined),
  email('Email', Icons.email_outlined);

  final String label;
  final IconData icon;
  const _FollowUpType(this.label, this.icon);
}

class _FollowUpTask {
  final String id;
  final String leadId;
  final String leadName;
  final String summary;
  final _FollowUpType type;
  final DateTime due;
  // No follow-up note — `ActivityQuickLogSheet` only captures notes for the
  // activity that just happened, not for the upcoming follow-up. If we want
  // historical context on the card later, carry over the parent activity's
  // notes (Option C in chat) — tracked as a future requirement.
  const _FollowUpTask({
    required this.id,
    required this.leadId,
    required this.leadName,
    required this.summary,
    required this.type,
    required this.due,
  });
}

/// Follow-up tasks screen. Two modes:
///   - [filter] set    → single bucket (Overdue OR Today)
///   - [filter] null   → combined: Overdue section followed by Today section
///                       in one scrollable. Sections are skipped if empty.
///
/// Production: data sourced from the existing `taskList` module filtered to
/// follow-up type + assigned RM = caller + due-date.
class FollowUpsScreen extends StatelessWidget {
  final FollowUpFilter? filter;
  const FollowUpsScreen({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    if (filter != null) {
      return _singleBucket(context, filter!);
    }
    return _combined(context);
  }

  Widget _singleBucket(BuildContext context, FollowUpFilter f) {
    final tasks = _mockTasks(f);
    return HeroScaffold(
      header: HeroAppBar.simple(
        title: f.title,
        subtitle: '${tasks.length} item${tasks.length == 1 ? '' : 's'}',
      ),
      body: tasks.isEmpty
          ? _EmptyState(filter: f)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FollowUpCard(
                task: tasks[i],
                isOverdue: f == FollowUpFilter.overdue,
              ),
            ),
    );
  }

  Widget _combined(BuildContext context) {
    final overdue = _mockTasks(FollowUpFilter.overdue);
    final today = _mockTasks(FollowUpFilter.today);
    final total = overdue.length + today.length;

    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Follow-ups',
        subtitle: '$total item${total == 1 ? '' : 's'}',
      ),
      body: total == 0
          ? _EmptyCombined()
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(
                    label: FollowUpFilter.overdue.sectionLabel,
                    count: overdue.length,
                    color: FollowUpFilter.overdue.accentColor,
                  ),
                  const SizedBox(height: 10),
                  ...overdue.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            _FollowUpCard(task: t, isOverdue: true),
                      )),
                  const SizedBox(height: 14),
                ],
                if (today.isNotEmpty) ...[
                  _SectionHeader(
                    label: FollowUpFilter.today.sectionLabel,
                    count: today.length,
                    color: FollowUpFilter.today.accentColor,
                  ),
                  const SizedBox(height: 10),
                  ...today.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child:
                            _FollowUpCard(task: t, isOverdue: false),
                      )),
                ],
              ],
            ),
    );
  }

  // Mock — replace with cubit + repo.
  List<_FollowUpTask> _mockTasks(FollowUpFilter f) {
    final now = DateTime.now();
    if (f == FollowUpFilter.overdue) {
      return [
        _FollowUpTask(
          id: 'FU-101',
          leadId: 'L-1042',
          leadName: 'Aanya Khanna',
          summary: 'EWG · Mumbai',
          type: _FollowUpType.call,
          due: now.subtract(const Duration(days: 2)),
        ),
        _FollowUpTask(
          id: 'FU-098',
          leadId: 'L-1037',
          leadName: 'Vikram Holdings Pvt Ltd',
          summary: 'PWG · Bengaluru',
          type: _FollowUpType.email,
          due: now.subtract(const Duration(days: 1)),
        ),
        _FollowUpTask(
          id: 'FU-090',
          leadId: 'L-1029',
          leadName: 'Rohan Kapoor',
          summary: 'EWG · Pune',
          type: _FollowUpType.meeting,
          due: now.subtract(const Duration(days: 3)),
        ),
      ];
    }
    return [
      _FollowUpTask(
        id: 'FU-110',
        leadId: 'L-1042',
        leadName: 'Aanya Khanna',
        summary: 'EWG · Mumbai',
        type: _FollowUpType.call,
        due: DateTime(now.year, now.month, now.day, 14, 30),
      ),
      _FollowUpTask(
        id: 'FU-111',
        leadId: 'L-1051',
        leadName: 'Sandeep Mehra',
        summary: 'EWG · Mumbai',
        type: _FollowUpType.meeting,
        due: DateTime(now.year, now.month, now.day, 16, 0),
      ),
      _FollowUpTask(
        id: 'FU-112',
        leadId: 'L-1062',
        leadName: 'Asha Krishnan',
        summary: 'PWG · Chennai',
        type: _FollowUpType.email,
        due: DateTime(now.year, now.month, now.day, 18, 0),
      ),
      _FollowUpTask(
        id: 'FU-113',
        leadId: 'L-1071',
        leadName: 'Patel Family Office',
        summary: 'PWG · Ahmedabad',
        type: _FollowUpType.call,
        due: DateTime(now.year, now.month, now.day, 11, 0),
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.roboto(
            color: const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString().padLeft(2, '0'),
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  final _FollowUpTask task;
  final bool isOverdue;
  const _FollowUpCard({required this.task, required this.isOverdue});

  String get _dueLabel {
    if (isOverdue) {
      final d = DateTime.now().difference(
          DateTime(task.due.year, task.due.month, task.due.day));
      final days = d.inDays;
      if (days == 0) return 'Due earlier today';
      if (days == 1) return 'Overdue 1 day';
      return 'Overdue $days days';
    }
    final h = task.due.hour;
    final m = task.due.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'am' : 'pm';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return 'Due at $hour12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(RouteNames.leadDetailPath(task.leadId)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: isOverdue
                    ? AppColors.errorRed
                    : AppColors.warmAmber,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(task.type.icon,
                        size: 18, color: AppColors.navyPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.leadName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.type.label} · ${task.summary}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isOverdue
                              ? AppColors.errorRed
                              : AppColors.warmAmber)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _dueLabel,
                      style: GoogleFonts.roboto(
                        color: isOverdue
                            ? AppColors.errorRed
                            : AppColors.warmAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onTap: () => _snack(context, 'Calling ${task.leadName}'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Mark done',
                    onTap: () => _snack(context, 'Marked done'),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.event_repeat_outlined,
                    label: 'Reschedule',
                    onTap: () => _snack(context, 'Reschedule ${task.id}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.navyPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                color: AppColors.navyPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final FollowUpFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.successGreen, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              filter.emptyTitle,
              style: GoogleFonts.roboto(
                color: AppColors.navyPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You're all caught up.",
              style: GoogleFonts.roboto(
                color: const Color(0xFF5A6B87),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCombined extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.successGreen, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'No follow-ups pending',
              style: GoogleFonts.roboto(
                color: AppColors.navyPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You're caught up across overdue and today.",
              style: GoogleFonts.roboto(
                color: const Color(0xFF5A6B87),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
