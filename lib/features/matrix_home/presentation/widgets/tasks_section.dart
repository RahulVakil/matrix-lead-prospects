import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/enums/ib_deal_type.dart' show IbLeadStatus;
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Wealth CRM module's contribution to the home Tasks rollup.
///
/// Scope: this prototype shows ONLY the 3 task rows added by the Wealth CRM
/// module, gated to RMs in the EWG / PWG verticals. Production tasks
/// (Liquidation, Shortfall, MTF, Nudges, Birthdays) are owned by other
/// modules and would render alongside these in the live app — they're
/// omitted here so the prototype stays focused on this module's surface.
///
/// Two urgency tiers in use (red ↑ Action now, amber – Today). No Tier 3
/// rows in this module's contribution.
enum _Tier {
  actionNow, // Tier 1 — overdue / blocked (red ↑)
  today;     // Tier 2 — scheduled for today (amber –)

  Color get color =>
      this == _Tier.actionNow ? AppColors.errorRed : AppColors.warmAmber;

  IconData get trendIcon => this == _Tier.actionNow
      ? Icons.arrow_upward_rounded
      : Icons.remove_rounded;
}

class _TaskEntry {
  final String title;
  final int count;
  final _Tier tier;
  final VoidCallback onTap;
  _TaskEntry(this.title, this.count, this.tier, this.onTap);
}

/// Mock counts. Production: home-counts endpoint that pulls from the task
/// module + IB module per the dev-team note in chat.
class _MockCounts {
  final int followUpsOverdue;
  final int followUpsDueToday;
  final int ibSentBack;

  const _MockCounts({
    required this.followUpsOverdue,
    required this.followUpsDueToday,
    required this.ibSentBack,
  });

  int get followUpsTotal => followUpsOverdue + followUpsDueToday;

  static const demo = _MockCounts(
    followUpsOverdue: 3,
    followUpsDueToday: 4,
    ibSentBack: 1,
  );
}

class TasksSection extends StatelessWidget {
  const TasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final tasks = _buildTasks(context, user, _MockCounts.demo);

    if (tasks.isEmpty) return const _WellDoneCard();

    final visible = tasks.take(5).toList();
    final hasOverflow = tasks.length > 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tasks',
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
                tasks.length.toString().padLeft(2, '0'),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (hasOverflow)
              _ShowAllButton(
                onTap: () => context.push(RouteNames.tasks),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: List.generate(visible.length, (i) {
              final t = visible[i];
              final isLast = i == visible.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: t.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFD2D9E5)),
                            ),
                            child: Text(
                              t.count.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF394150),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _TrendDot(tier: t.tier),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Wealth-RM (EWG / PWG) only. Other roles see no rows from this module —
  /// in production, their home would show only their module's tasks.
  List<_TaskEntry> _buildTasks(
    BuildContext context,
    UserModel user,
    _MockCounts c,
  ) {
    final isWealthRm = user.role == UserRole.rm &&
        (user.vertical == null ||
            user.vertical == 'EWG' ||
            user.vertical == 'PWG');
    if (!isWealthRm) return const [];

    final list = <_TaskEntry>[];
    void add(String title, int count, _Tier tier, VoidCallback onTap) {
      if (count > 0) list.add(_TaskEntry(title, count, tier, onTap));
    }

    // Combined Follow-ups row — merges overdue + today into a single
    // tappable entry. Tier escalates to actionNow when overdue ≥ 1, else
    // sits at today (amber). Lands on the combined FollowUpsScreen which
    // renders Overdue then Today as sequential sections in one scroll.
    final fuTier = c.followUpsOverdue > 0 ? _Tier.actionNow : _Tier.today;
    add('Follow-ups', c.followUpsTotal, fuTier,
        () => context.push(RouteNames.followUps));
    add('IB leads sent back', c.ibSentBack, _Tier.actionNow,
        () => context.push(RouteNames.ibLeads,
            extra: {'status': IbLeadStatus.sentBack}));

    return list;
  }
}

class _TrendDot extends StatelessWidget {
  final _Tier tier;
  const _TrendDot({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(tier.trendIcon, size: 14, color: tier.color),
    );
  }
}

class _ShowAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right,
                color: AppColors.navyPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _WellDoneCard extends StatelessWidget {
  const _WellDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
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
            'Well Done for Today',
            style: GoogleFonts.roboto(
              color: AppColors.navyPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You've addressed all scheduled items.",
            style: GoogleFonts.roboto(
              color: const Color(0xFF5A6B87),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
