import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/home_cubit.dart';

/// Home — the Lead module landing page.
/// Greeting · Stat strip · Quick actions row · Today queue · Pipeline.
/// Every sub-option of the Lead module is reachable from this page.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => HomeCubit(rmId: user.id)..loadData(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return HeroScaffold(
            header: _HomeHeroHeader(
              userName: user.name,
              onBellTap: () => context.push('/notifications'),
            ),
            floatingActionButton: _AddFab(
              onTap: () => context.push('/leads/new'),
            ),
            body: state.isLoading
                ? const Center(child: CompassLoader())
                : RefreshIndicator(
                    color: AppColors.navyPrimary,
                    onRefresh: () => context.read<HomeCubit>().loadData(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 110),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${Formatters.greeting()}, ${user.name.split(' ').first}',
                                style: AppTextStyles.heading2.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.dayOfWeek(),
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 18),
                              _StatStrip(
                                todayCount: state.todayItems.length,
                                dueNowCount: state.dueNowItems.length,
                                pipelineCount: state.totalLeads,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Quick actions: every sub-option of the Lead module ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text(
                            'QUICK ACTIONS',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _QuickActionsRow(role: user.role),
                        const SizedBox(height: 22),

                        if (state.dueNowItems.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _DueNowStrip(count: state.dueNowItems.length),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: state.todayItems.isEmpty
                              ? const _AllCaughtUp()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionRow(
                                      title: 'Today',
                                      count: state.todayItems.length,
                                      actionLabel: 'View all',
                                      onAction: () => context.push(RouteNames.leads),
                                    ),
                                    const SizedBox(height: 12),
                                    ...state.todayItems.take(8).map(
                                          (item) => _TodayCard(
                                            item: item,
                                            onTap: () => context.push(
                                              RouteNames.leadDetailPath(item.lead.id),
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionRow(
                                title: 'My pipeline',
                                count: state.totalLeads,
                                actionLabel: null,
                                onAction: null,
                              ),
                              const SizedBox(height: 12),
                              _PipelineCard(summary: state.pipelineSummary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Quick actions row — horizontal scroll, role-aware
// ────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final UserRole role;
  const _QuickActionsRow({required this.role});

  List<_QAItem> _itemsFor(BuildContext context) {
    final items = <_QAItem>[
      _QAItem(
        icon: Icons.people_alt_outlined,
        label: 'All leads',
        color: AppColors.navyPrimary,
        onTap: () => context.push('/leads'),
      ),
      _QAItem(
        icon: Icons.person_add_alt_1,
        label: 'New lead',
        color: AppColors.tealAccent,
        onTap: () => context.push('/leads/new'),
      ),
      _QAItem(
        icon: Icons.shield_outlined,
        label: 'Coverage',
        color: AppColors.warmAmber,
        onTap: () => context.push('/coverage'),
      ),
      _QAItem(
        icon: Icons.business_center_outlined,
        label: 'IB lead',
        color: AppColors.stageOpportunity,
        onTap: () => context.push('/ib-leads/new'),
      ),
    ];

    // Role-gated additions
    if (role == UserRole.rm) {
      items.add(_QAItem(
        icon: Icons.move_to_inbox_outlined,
        label: 'Get lead',
        color: AppColors.coldBlue,
        onTap: () => context.push('/get-lead'),
      ));
    }
    if (role == UserRole.branchManager || role == UserRole.admin) {
      items.add(_QAItem(
        icon: Icons.fact_check_outlined,
        label: 'IB approvals',
        color: AppColors.stageOpportunity,
        onTap: () => context.push('/ib-leads'),
      ));
    }
    if (role == UserRole.checker || role == UserRole.admin) {
      items.add(_QAItem(
        icon: Icons.verified_user_outlined,
        label: 'Profiling',
        color: AppColors.stageProfiling,
        onTap: () => context.push('/profiling/queue'),
      ));
    }
    if (role == UserRole.teamLead || role == UserRole.admin) {
      items.add(_QAItem(
        icon: Icons.dashboard_outlined,
        label: 'Team',
        color: AppColors.tealAccent,
        onTap: () => context.push('/tl/dashboard'),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _QACard(item: items[i]),
      ),
    );
  }
}

class _QAItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QAItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QACard extends StatelessWidget {
  final _QAItem item;
  const _QACard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderDefault.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Hero header — avatar circle + welcome + notification bell
// ────────────────────────────────────────────────────────────────────

class _HomeHeroHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onBellTap;

  const _HomeHeroHeader({required this.userName, required this.onBellTap});

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.fromLTRB(18, topInset + 14, 14, 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MATRIX',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Leads',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onBellTap,
                splashRadius: 22,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDA251D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Stat strip — three numbers in a single hero row
// ────────────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  final int todayCount;
  final int dueNowCount;
  final int pipelineCount;

  const _StatStrip({
    required this.todayCount,
    required this.dueNowCount,
    required this.pipelineCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('$todayCount', 'Today', AppColors.navyPrimary),
          _divider(),
          _stat(
            '$dueNowCount',
            'Due now',
            dueNowCount > 0 ? AppColors.warmAmber : AppColors.textSecondary,
          ),
          _divider(),
          _stat('$pipelineCount', 'Pipeline', AppColors.tealAccent),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.borderDefault.withValues(alpha: 0.6),
      );
}

// ────────────────────────────────────────────────────────────────────
// Due-now strip
// ────────────────────────────────────────────────────────────────────

class _DueNowStrip extends StatelessWidget {
  final int count;
  const _DueNowStrip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warmAmber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm, color: AppColors.warmAmber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DUE IN NEXT 30 MIN',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warmAmber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count == 1 ? '' : 's'} need your attention',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Section row label
// ────────────────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionRow({
    required this.title,
    required this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.navyPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.navyPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: AppColors.navyPrimary, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Today card
// ────────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final TodayItem item;
  final VoidCallback onTap;

  const _TodayCard({required this.item, required this.onTap});

  Color get _accent => switch (item.reason) {
        TodayReason.overdueCallback => AppColors.errorRed,
        TodayReason.callbackToday => AppColors.warmAmber,
        TodayReason.meetingToday => AppColors.warmAmber,
        TodayReason.followUpDue => AppColors.warmAmber,
        TodayReason.newOvernight => AppColors.coldBlue,
        TodayReason.hotInactive => AppColors.hotRed,
        TodayReason.proposalDue => AppColors.tealAccent,
      };

  String get _initials {
    final parts = item.lead.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return item.lead.fullName.substring(
      0,
      item.lead.fullName.length >= 2 ? 2 : 1,
    ).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final lead = item.lead;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lead.fullName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.reason.label,
                              style: AppTextStyles.caption.copyWith(
                                color: _accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              lead.lastContactDisplay,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Pipeline card
// ────────────────────────────────────────────────────────────────────

class _PipelineCard extends StatelessWidget {
  final Map<LeadStage, int> summary;
  const _PipelineCard({required this.summary});

  static const _order = [
    LeadStage.lead,
    LeadStage.engage,
    LeadStage.opportunity,
    LeadStage.profiling,
    LeadStage.client,
  ];

  @override
  Widget build(BuildContext context) {
    final maxCount = _order.fold<int>(
      0,
      (m, s) => (summary[s] ?? 0) > m ? (summary[s] ?? 0) : m,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _order.map((stage) {
          final count = summary[stage] ?? 0;
          final ratio = maxCount == 0 ? 0.0 : count / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    stage.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: stage.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 26,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: stage.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// All-caught-up empty state
// ────────────────────────────────────────────────────────────────────

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.successGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "You're all caught up",
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Nothing urgent right now.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// FAB — single-tap shortcut to New Lead
// ────────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyPrimary, AppColors.navyDark],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
