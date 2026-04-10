import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/temp_pill.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/home_cubit.dart';

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
          if (state.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.surfaceTertiary,
              body: CompassLoader(),
            );
          }
          return Scaffold(
            backgroundColor: AppColors.surfaceTertiary,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showFabMenu(context),
              backgroundColor: AppColors.navyPrimary,
              child: const Icon(Icons.add, color: AppColors.textOnDark),
            ),
            body: RefreshIndicator(
              color: AppColors.navyPrimary,
              onRefresh: () => context.read<HomeCubit>().loadData(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    '${Formatters.greeting()}, ${user.name.split(' ').first}',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 2),
                  Text(Formatters.dayOfWeek(), style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),

                  if (state.dueNowItems.isNotEmpty) ...[
                    _DueNowBanner(items: state.dueNowItems),
                    const SizedBox(height: 16),
                  ],

                  if (state.todayItems.isEmpty)
                    const _AllCaughtUp()
                  else ...[
                    CompassSectionHeader(
                      title: 'Today',
                      count: state.todayItems.length,
                      actionLabel: 'View all',
                      onActionTap: () => context.push(RouteNames.leads),
                    ),
                    const SizedBox(height: 10),
                    ...state.todayItems.take(8).map(
                          (item) => _TodayCard(
                            item: item,
                            onTap: () => context.push(
                              RouteNames.leadDetailPath(item.lead.id),
                            ),
                          ),
                        ),
                  ],

                  const SizedBox(height: 24),
                  _PipelineStrip(summary: state.pipelineSummary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showFabMenu(BuildContext context) {
  showCompassSheet(
    context,
    title: 'Quick actions',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fabRow(
          context,
          icon: Icons.person_add_alt_1,
          label: 'New Lead',
          subtitle: 'Capture a new prospect',
          onTap: () {
            Navigator.of(context).pop();
            context.push('/leads/new');
          },
        ),
        _fabRow(
          context,
          icon: Icons.business_center,
          label: 'Capture IB Lead',
          subtitle: 'Investment Banking opportunity',
          onTap: () {
            Navigator.of(context).pop();
            context.push('/ib-leads/new');
          },
        ),
        _fabRow(
          context,
          icon: Icons.shield_outlined,
          label: 'Coverage Check',
          subtitle: 'Search before you capture',
          onTap: () {
            Navigator.of(context).pop();
            context.push('/coverage');
          },
        ),
      ],
    ),
  );
}

Widget _fabRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.navyPrimary),
    ),
    title: Text(label, style: AppTextStyles.labelLarge),
    subtitle: Text(subtitle, style: AppTextStyles.caption),
    onTap: onTap,
  );
}

class _DueNowBanner extends StatelessWidget {
  final List items;
  const _DueNowBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, color: AppColors.warmAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Due in the next 30 minutes',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warmAmber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'} need your attention',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final TodayItem item;
  final VoidCallback onTap;

  const _TodayCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lead = item.lead;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CompassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            AvatarCircle(name: lead.fullName, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead.fullName,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TempPill(temperature: lead.temperature, showLabel: false),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _ReasonChip(reason: item.reason),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lead.lastContactDisplay,
                          style: AppTextStyles.caption,
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
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final TodayReason reason;
  const _ReasonChip({required this.reason});

  Color get _color => switch (reason) {
        TodayReason.overdueCallback => AppColors.errorRed,
        TodayReason.callbackToday => AppColors.warmAmber,
        TodayReason.meetingToday => AppColors.warmAmber,
        TodayReason.followUpDue => AppColors.warmAmber,
        TodayReason.newOvernight => AppColors.coldBlue,
        TodayReason.hotInactive => AppColors.hotRed,
        TodayReason.proposalDue => AppColors.tealAccent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reason.label,
        style: AppTextStyles.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PipelineStrip extends StatelessWidget {
  final Map<LeadStage, int> summary;
  const _PipelineStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final order = [
      LeadStage.lead,
      LeadStage.engage,
      LeadStage.opportunity,
      LeadStage.profiling,
      LeadStage.client,
    ];
    return CompassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompassSectionHeader(title: 'My Pipeline'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: order.map((s) {
              final c = summary[s] ?? 0;
              return Column(
                children: [
                  Text(
                    '$c',
                    style: AppTextStyles.heading2.copyWith(
                      color: s.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(s.label, style: AppTextStyles.caption),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return const CompassEmptyState(
      icon: Icons.check_circle_outline,
      title: "You're all caught up",
      subtitle: 'No urgent items right now',
    );
  }
}
