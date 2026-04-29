import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/leadership_dashboard_cubit.dart';

/// Leadership Dashboard — single screen used by Team Lead, Regional Head,
/// Zonal Head, CEO and Admin/MIS. Layout (KPI strip + Pipeline by stage +
/// Children breakdown + Activity 24h) is identical at every level; only
/// the data scope changes. Children rows drill down to the next level
/// (zone → region → team → RM); from a Team-scope view, tapping an RM
/// row navigates to that RM's personal `LeadsDashboardScreen`.
class LeadershipDashboardScreen extends StatelessWidget {
  /// When null, the natural scope is derived from the logged-in user's role.
  final LeadershipLevel? overrideLevel;
  final String? overrideScopeId;
  final String? overrideScopeName;

  const LeadershipDashboardScreen({
    super.key,
    this.overrideLevel,
    this.overrideScopeId,
    this.overrideScopeName,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    // Resolve the effective scope. Order of precedence:
    //   1) explicit overrides (used by drill-down navigation)
    //   2) the user's natural leadership level
    //   3) fall back to `all` so leadership users without a populated
    //      scope still get a usable view.
    final level = overrideLevel ??
        user.role.leadershipLevel ??
        LeadershipLevel.all;
    String? scopeId = overrideScopeId;
    String? scopeName = overrideScopeName;
    if (overrideLevel == null) {
      switch (level) {
        case LeadershipLevel.team:
          scopeId = user.teamId;
          scopeName = user.teamName ?? user.teamId;
          break;
        case LeadershipLevel.region:
          scopeId = user.regionName;
          scopeName = user.regionName;
          break;
        case LeadershipLevel.zone:
          scopeId = user.zoneName;
          scopeName = user.zoneName;
          break;
        case LeadershipLevel.all:
          scopeName = 'Organization';
          break;
      }
    }

    return BlocProvider(
      create: (_) => LeadershipDashboardCubit(
        level: level,
        scopeId: scopeId,
        scopeName: scopeName,
      )..load(),
      child: BlocBuilder<LeadershipDashboardCubit, LeadershipDashboardState>(
        builder: (context, state) {
          final title = '${level.label} dashboard';
          final subtitle = scopeName ?? '';
          return HeroScaffold(
            header: HeroAppBar.simple(title: title, subtitle: subtitle),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppColors.navyPrimary,
              onPressed: () => context.push('/leads/new'),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: state.isLoading
                ? const Center(child: CompassLoader())
                : RefreshIndicator(
                    color: AppColors.navyPrimary,
                    onRefresh: () =>
                        context.read<LeadershipDashboardCubit>().load(),
                    child: ListView(
                      padding: const EdgeInsets.all(
                          AppDimensions.screenPadding),
                      children: [
                        _kpiStrip(context, state),
                        const SizedBox(height: 24),
                        _pipelineSection(state),
                        const SizedBox(height: 24),
                        _childrenSection(context, state),
                        const SizedBox(height: 24),
                        _activitySection(state),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ── KPI strip ──────────────────────────────────────────────────────

  Widget _kpiStrip(BuildContext context, LeadershipDashboardState s) {
    // Six spec'd widgets + one insightful add-on (Conversion Rate %).
    // Laid out as 3 rows of 3 — leaving the bottom-right slot for a
    // leadership-friendly Conversion Rate tile so the strip reads as
    // 6 hard counts + 1 derived metric.
    final convRate =
        '${s.conversionRatePct.toStringAsFixed(s.conversionRatePct >= 10 ? 0 : 1)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.level.label.toUpperCase()} OVERVIEW',
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(
          children: [
            _kpi('Total Leads', '${s.totalLeads}', AppColors.navyPrimary,
                onTap: () => context.push('/leads', extra: const {
                      'activeOnly': true,
                      'title': 'Total leads',
                    })),
            const SizedBox(width: 12),
            _kpi('Hot Leads', '${s.hotCount}', AppColors.hotRed,
                onTap: () => context.push('/leads', extra: const {
                      'status': 'hot',
                      'activeOnly': true,
                      'title': 'Hot leads',
                    })),
            const SizedBox(width: 12),
            _kpi('Converted', '${s.conversions}', AppColors.successGreen,
                onTap: () => context.push('/leads', extra: const {
                      'status': 'onboarded',
                      'title': 'Onboarded leads',
                    })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _kpi('IB Leads', '${s.ibCount}', AppColors.stageOpportunity,
                onTap: () => context.push('/ib-leads')),
            const SizedBox(width: 12),
            _kpi('Hurun', '${s.hurunCount}', AppColors.tealAccent,
                onTap: () => context.push('/leads', extra: const {
                      'source': 'hurun',
                      'activeOnly': true,
                      'title': 'Hurun leads',
                    })),
            const SizedBox(width: 12),
            _kpi('Monetization Events', '${s.monetizationEventCount}',
                AppColors.warmAmber,
                onTap: () => context.push('/leads', extra: const {
                      'source': 'monetizationEvent',
                      'activeOnly': true,
                      'title': 'Monetization Event leads',
                    })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Conversion Rate stays a non-clickable derived metric.
            _kpi('Conversion Rate', convRate, AppColors.navyDark),
          ],
        ),
      ],
    );
  }

  Widget _kpi(String label, String value, Color color, {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading1.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
    return Expanded(
      child: onTap == null
          ? card
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: card,
            ),
    );
  }

  // ── Pipeline by stage ──────────────────────────────────────────────

  Widget _pipelineSection(LeadershipDashboardState s) {
    // Unified Lead Funnel — 4 buckets aligned with the new "Status"
    // vocabulary: Hot / Warm / Cold / Onboarded. With the LeadModel
    // temperature getter routing onboarded leads to the new
    // `onboarded` enum value, the cubit's hotCount/warmCount/coldCount
    // already exclude onboarded leads, so adding the Onboarded bar
    // (sourced from `s.conversions`) cannot double-count.
    final stages = [
      ('Hot', s.hotCount, AppColors.hotRed),
      ('Warm', s.warmCount, AppColors.warmAmber),
      ('Cold', s.coldCount, AppColors.coldBlue),
      ('Onboarded', s.conversions, AppColors.successGreen),
    ];
    final total = stages.fold<int>(0, (sum, st) => sum + st.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LEAD FUNNEL',
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: total == 0
              ? Text('No leads in this scope yet.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint))
              : Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: stages.map((st) {
                          return Expanded(
                            flex: st.$2 == 0 ? 1 : st.$2,
                            child: Container(
                              height: 24,
                              color: st.$2 == 0
                                  ? AppColors.borderDefault
                                  : st.$3,
                              alignment: Alignment.center,
                              child: Text('${st.$2}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textOnDark,
                                      fontWeight: FontWeight.w600)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: stages
                          .map((st) =>
                              Text(st.$1, style: AppTextStyles.caption))
                          .toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Children breakdown ─────────────────────────────────────────────

  String _childrenLabel(LeadershipLevel level) {
    switch (level) {
      case LeadershipLevel.team:
        return 'RM PERFORMANCE';
      case LeadershipLevel.region:
        return 'TEAM PERFORMANCE';
      case LeadershipLevel.zone:
        return 'REGION PERFORMANCE';
      case LeadershipLevel.all:
        return 'ZONE PERFORMANCE';
    }
  }

  Widget _childrenSection(
      BuildContext context, LeadershipDashboardState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_childrenLabel(s.level),
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        if (s.children.isEmpty)
          _emptyCard('No data in this scope.')
        else
          ...s.children.map((row) => _childRow(context, row, s.level)),
      ],
    );
  }

  Widget _childRow(BuildContext context, ChildBreakdownRow row,
      LeadershipLevel parentLevel) {
    final initials = row.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (row.childLevel == null) {
            // Leaf row (RM) — drill into the RM's personal pipeline.
            context.push('/leads-dashboard',
                extra: {'rmId': row.id, 'rmName': row.name});
          } else {
            // Push another LeadershipDashboardScreen with the child scope.
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LeadershipDashboardScreen(
                overrideLevel: row.childLevel,
                overrideScopeId: row.id,
                overrideScopeName: row.name,
              ),
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.avatarBackground,
                child: Text(
                  initials.isEmpty ? '·' : initials,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.navyDark,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.name, style: AppTextStyles.labelLarge),
                    Text(
                      '${row.leadCount} leads · ${row.hotCount} hot · ${row.conversions} converted · ${row.ibApproved} IB',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  // ── Activity 24h ──────────────────────────────────────────────────

  Widget _activitySection(LeadershipDashboardState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.level.label.toUpperCase()} ACTIVITY (LAST 24H)',
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        _activityStat(Icons.phone, 'Calls Made', s.activity.calls),
        _activityStat(
            Icons.calendar_today, 'Meetings Scheduled', s.activity.meetings),
        _activityStat(Icons.note_alt_outlined, 'Notes Logged', s.activity.notes),
        _activityStat(
            Icons.arrow_upward, 'Stage Advances', s.activity.stageAdvances),
        _activityStat(Icons.trending_down, 'Leads Lost', s.activity.dropped),
      ],
    );
  }

  Widget _activityStat(IconData icon, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text('$value',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.navyPrimary)),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(message,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
    );
  }
}
