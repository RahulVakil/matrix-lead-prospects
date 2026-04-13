import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/leads_dashboard_cubit.dart';

/// Leads Dashboard — production-grade home with visual funnel,
/// prominent totals, dropped count, and action-today.
class LeadsDashboardScreen extends StatelessWidget {
  final String? rmId;
  final String? rmName;

  const LeadsDashboardScreen({super.key, this.rmId, this.rmName});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    // If rmId is provided (e.g. TL clicked an RM), show that RM's data
    final effectiveRmId = rmId ?? user.id;
    final effectiveName = rmName ?? user.name;
    final isViewingOwnData = rmId == null;

    return BlocProvider(
      create: (_) => LeadsDashboardCubit(
        rmId: effectiveRmId,
        isRm: isViewingOwnData && user.role == UserRole.rm,
      )..load(),
      child: BlocBuilder<LeadsDashboardCubit, LeadsDashboardState>(
        builder: (context, state) {
          return HeroScaffold(
            header: _DashHeader(
              name: effectiveName,
              role: user.role,
              totalLeads: state.totalLeads,
              subtitle: !isViewingOwnData ? "${effectiveName}'s pipeline" : null,
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
                        // ── Prominent total + temperature strip ───
                        _TotalHeroCard(state: state),
                        const SizedBox(height: 18),

                        // ── Quick actions ─────────────────────────
                        _QuickActions(),
                        const SizedBox(height: 22),

                        // ── Visual funnel ─────────────────────────
                        _SectionTitle('Lead funnel'),
                        const SizedBox(height: 12),
                        _VisualFunnel(state: state),
                        const SizedBox(height: 22),

                        // ── Action today ──────────────────────────
                        _SectionTitle('Action today', count: state.actionToday.length),
                        const SizedBox(height: 12),
                        if (state.actionToday.isEmpty)
                          _emptyCard('All clear — nothing urgent')
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

                        // IB sent-back section
                        if (state.ibSentBack.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _SectionTitle('IB leads sent back', count: state.ibSentBack.length),
                          const SizedBox(height: 12),
                          ...state.ibSentBack.map((ib) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: AppColors.surfacePrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => context.push(RouteNames.ibLeadDetailPath(ib.id)),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.replay, size: 16, color: AppColors.warmAmber),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(ib.companyName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                                              ),
                                              Text(ib.dealType.label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                                            ],
                                          ),
                                          if (ib.remarks != null && ib.remarks!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.warmAmber.withValues(alpha: 0.06),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.comment_outlined, size: 14, color: AppColors.warmAmber),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      ib.remarks!,
                                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                                                      maxLines: 3,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ],
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
// Dashboard hero header
// ────────────────────────────────────────────────────────────────────

class _DashHeader extends StatelessWidget {
  final String name;
  final UserRole role;
  final int totalLeads;
  final String? subtitle;

  const _DashHeader({required this.name, required this.role, required this.totalLeads, this.subtitle});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.fromLTRB(18, topInset + 12, 14, 18),
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
                  'MATRIX LEADS',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.split(' ').first,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            splashRadius: 22,
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Total hero card — prominent total + hot/warm/cold + dropped
// ────────────────────────────────────────────────────────────────────

class _TotalHeroCard extends StatelessWidget {
  final LeadsDashboardState state;
  const _TotalHeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyPrimary, AppColors.navyDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.totalLeads}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Active leads',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (state.droppedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_circle_outline, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${state.droppedCount} dropped',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tempPill('Hot', state.hotCount, AppColors.hotRed),
              const SizedBox(width: 10),
              _tempPill('Warm', state.warmCount, AppColors.warmAmber),
              const SizedBox(width: 10),
              _tempPill('Cold', state.coldCount, AppColors.coldBlue),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.overallConversion.toStringAsFixed(0)}% converted',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tempPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Visual funnel — trapezoid-shaped stage bars narrowing top to bottom
// ────────────────────────────────────────────────────────────────────

class _VisualFunnel extends StatelessWidget {
  final LeadsDashboardState state;
  const _VisualFunnel({required this.state});

  @override
  Widget build(BuildContext context) {
    final stages = LeadStage.activePipeline;
    final maxCount = stages.fold<int>(
      0,
      (m, s) => (state.pipeline[s] ?? 0) > m ? (state.pipeline[s] ?? 0) : m,
    );
    final totalActive = stages.fold<int>(0, (s, st) => s + (state.pipeline[st] ?? 0));
    final onboardCount = state.pipeline[LeadStage.onboard] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ...List.generate(stages.length, (i) {
            final stage = stages[i];
            final count = state.pipeline[stage] ?? 0;
            // True funnel: size relative to first stage (Lead), not max
            final leadCount = state.pipeline[stages.first] ?? 1;
            final widthFraction = leadCount == 0
                ? (1.0 - i * 0.2).clamp(0.15, 1.0)
                : (i == 0 ? 1.0 : (count / leadCount).clamp(0.15, 1.0));
            return _FunnelBar(
              stage: stage,
              count: count,
              widthFraction: widthFraction,
              isLast: i == stages.length - 1,
            );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 18, color: AppColors.successGreen),
                const SizedBox(width: 8),
                Text(
                  'Lead → Onboarded: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  totalActive > 0
                      ? '${(onboardCount / totalActive * 100).toStringAsFixed(0)}%'
                      : '—',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '  ($onboardCount of $totalActive)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.successGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final LeadStage stage;
  final int count;
  final double widthFraction;
  final bool isLast;

  const _FunnelBar({
    required this.stage,
    required this.count,
    required this.widthFraction,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  stage.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: widthFraction,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: stage.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: stage.color.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: stage.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 85),
              child: Icon(
                Icons.arrow_drop_down,
                color: AppColors.textHint.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Quick actions
// ────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _qa(Icons.people_alt_outlined, 'All leads', AppColors.navyPrimary,
            () => context.push(RouteNames.leads)),
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
// Section title + action card + empty card
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
