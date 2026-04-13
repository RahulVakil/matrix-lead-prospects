import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/leads_dashboard_cubit.dart';

/// Leads Dashboard — the module landing page. Accessed from More → Leads.
/// Total leads strip, action today, pipeline funnel, quick actions.
class LeadsDashboardScreen extends StatelessWidget {
  const LeadsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => LeadsDashboardCubit(rmId: user.id)..load(),
      child: BlocBuilder<LeadsDashboardCubit, LeadsDashboardState>(
        builder: (context, state) {
          return HeroScaffold(
            header: HeroAppBar.simple(
              title: 'Leads',
              subtitle: '${state.totalLeads} total',
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => context.push('/notifications'),
                  splashRadius: 22,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppColors.navyPrimary,
              onPressed: () => context.push('/leads/new'),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: state.isLoading
                ? const Center(child: CompassLoader())
                : RefreshIndicator(
                    color: AppColors.navyPrimary,
                    onRefresh: () => context.read<LeadsDashboardCubit>().load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                      children: [
                        // Total leads strip
                        _TotalStrip(
                          total: state.totalLeads,
                          hot: state.hotCount,
                          warm: state.warmCount,
                          cold: state.coldCount,
                        ),
                        const SizedBox(height: 22),

                        // Quick actions
                        _QuickActions(onAllLeads: () => context.push(RouteNames.leads)),
                        const SizedBox(height: 22),

                        // Action today
                        _SectionTitle('Leads to action today', count: state.actionToday.length),
                        const SizedBox(height: 12),
                        if (state.actionToday.isEmpty)
                          _emptyCard('All clear — nothing needs attention right now')
                        else
                          ...state.actionToday.take(5).map((item) => _ActionCard(
                                item: item,
                                onTap: () => context.push(
                                  RouteNames.leadDetailPath(item.lead.id),
                                ),
                              )),
                        if (state.actionToday.length > 5) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => context.push(RouteNames.leads),
                              child: Text(
                                'Show all ${state.actionToday.length}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.navyPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),

                        // Pipeline funnel
                        _SectionTitle('Lead pipeline'),
                        const SizedBox(height: 12),
                        _PipelineFunnel(state: state),
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
// Total strip — Hot | Warm | Cold
// ────────────────────────────────────────────────────────────────────

class _TotalStrip extends StatelessWidget {
  final int total;
  final int hot;
  final int warm;
  final int cold;

  const _TotalStrip({
    required this.total,
    required this.hot,
    required this.warm,
    required this.cold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          _tempCell('$hot', 'Hot', AppColors.hotRed),
          _divider(),
          _tempCell('$warm', 'Warm', AppColors.warmAmber),
          _divider(),
          _tempCell('$cold', 'Cold', AppColors.coldBlue),
        ],
      ),
    );
  }

  Widget _tempCell(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.borderDefault.withValues(alpha: 0.5),
      );
}

// ────────────────────────────────────────────────────────────────────
// Quick actions
// ────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onAllLeads;
  const _QuickActions({required this.onAllLeads});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _qa(Icons.people_alt_outlined, 'All leads', AppColors.navyPrimary,
            onAllLeads),
        const SizedBox(width: 10),
        _qa(Icons.person_add_alt_1, 'New lead', AppColors.tealAccent,
            () => context.push('/leads/new')),
        const SizedBox(width: 10),
        _qa(Icons.move_to_inbox_outlined, 'Get lead', AppColors.coldBlue,
            () => context.push('/get-lead')),
        const SizedBox(width: 10),
        _qa(Icons.business_center_outlined, 'IB lead', AppColors.stageOpportunity,
            () => context.push('/ib-leads/new')),
      ],
    );
  }

  Widget _qa(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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
// Section title
// ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionTitle(this.title, {this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        if (count != null) ...[
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
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Action today card
// ────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final ActionTodayItem item;
  final VoidCallback onTap;

  const _ActionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lead = item.lead;
    final color = lead.temperature.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.fullName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.actionSummary,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Pipeline funnel with conversion %
// ────────────────────────────────────────────────────────────────────

class _PipelineFunnel extends StatelessWidget {
  final LeadsDashboardState state;
  const _PipelineFunnel({required this.state});

  @override
  Widget build(BuildContext context) {
    final stages = LeadStage.activePipeline;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: List.generate(stages.length, (i) {
          final stage = stages[i];
          final count = state.pipeline[stage] ?? 0;
          final isLast = i == stages.length - 1;
          return Column(
            children: [
              _stageRow(stage, count),
              if (!isLast) ...[
                _conversionArrow(
                  state.conversionRate(stages[i], stages[i + 1]),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _stageRow(LeadStage stage, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: stage.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stage.label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: AppTextStyles.heading3.copyWith(
              color: stage.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversionArrow(double rate) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_downward, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            '${rate.toStringAsFixed(0)}% conversion',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _emptyCard(String message) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
    decoration: BoxDecoration(
      color: AppColors.surfacePrimary,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: AppTextStyles.bodySmall),
        ),
      ],
    ),
  );
}
