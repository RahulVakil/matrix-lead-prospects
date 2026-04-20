import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/get_lead_cubit.dart';

/// Get Lead — RM / TL flow to request fresh leads from the shared pool.
/// Dashboard tiles, weekly cap explainer, count input, recent claims.
class GetLeadScreen extends StatelessWidget {
  const GetLeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => GetLeadCubit(rmId: user.id)..init(),
      child: const _GetLeadBody(),
    );
  }
}

class _GetLeadBody extends StatelessWidget {
  const _GetLeadBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GetLeadCubit, GetLeadState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (context, state) {
        showCompassSnack(
          context,
          message: state.error!,
          type: CompassSnackType.warn,
        );
      },
      builder: (context, state) {
        return HeroScaffold(
          header: HeroAppBar.simple(
            title: 'Get a lead',
            subtitle: 'From the shared JMFS pool',
          ),
          body: state.isLoading
              ? const Center(child: CompassLoader())
              : RefreshIndicator(
                  color: AppColors.navyPrimary,
                  onRefresh: () => context.read<GetLeadCubit>().init(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _DashboardTiles(data: state.dashboard!),
                      const SizedBox(height: 16),
                      _WeeklyCapBanner(data: state.dashboard!),
                      const SizedBox(height: 16),
                      _RequestForm(state: state),
                      if (state.recentClaims.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _RecentClaims(claims: state.recentClaims),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DashboardTiles extends StatelessWidget {
  final dynamic data;
  const _DashboardTiles({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Tile(
          label: 'Total JMFS pool leads',
          value: '${d.totalPoolLeads}',
          color: AppColors.navyPrimary,
          icon: Icons.inventory_2_outlined,
        ),
        _Tile(
          label: 'Leads requested by you (ITD)',
          value: '${d.leadsRequestedItd}',
          color: AppColors.tealAccent,
          icon: Icons.outbox_outlined,
        ),
        _Tile(
          label: 'Requested leads dropped (ITD)',
          value: '${d.requestedLeadsDroppedItd}',
          color: AppColors.errorRed,
          icon: Icons.remove_circle_outline,
        ),
        _Tile(
          label: 'Pool leads converted (ITD)',
          value: '${d.poolLeadsConvertedItd}',
          color: AppColors.successGreen,
          icon: Icons.verified_outlined,
        ),
      ]
          .map((w) => SizedBox(
                width: (MediaQuery.of(context).size.width - 32 - 10) / 2,
                child: w,
              ))
          .toList(),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Tile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCapBanner extends StatelessWidget {
  final dynamic data;
  const _WeeklyCapBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final color = d.remainingThisWeek > 0
        ? AppColors.navyPrimary
        : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(color: color),
                children: [
                  TextSpan(
                    text: '${d.remainingThisWeek}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' left this week '),
                  TextSpan(
                    text:
                        '(cap ${d.effectiveWeeklyCap}, used ${d.claimsInLast7Days})',
                    style: AppTextStyles.caption.copyWith(
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                  if (d.wrongContactDropsInLast7Days > 0) ...[
                    const TextSpan(text: '  •  '),
                    TextSpan(
                      text:
                          '+${d.wrongContactDropsInLast7Days} bonus from wrong-contact drops',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  final GetLeadState state;
  const _RequestForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.dashboard!;
    final available =
        d.remainingThisWeek > 0 && d.totalPoolLeads > 0 && !state.isSubmitting;
    final maxRequestable = d.remainingThisWeek < d.totalPoolLeads
        ? d.remainingThisWeek
        : d.totalPoolLeads;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many leads do you want?',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stepper(
                value: state.requestedCount,
                min: 0,
                max: maxRequestable,
                onChanged: available
                    ? (v) =>
                        context.read<GetLeadCubit>().setRequestedCount(v)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will receive ${state.requestedCount} lead${state.requestedCount == 1 ? '' : 's'} from the pool.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CompassButton(
              label: state.isSubmitting
                  ? 'Requesting…'
                  : 'Request leads',
              isLoading: state.isSubmitting,
              onPressed: available && state.requestedCount > 0
                  ? () async {
                      final user =
                          context.read<AuthCubit>().state.currentUser;
                      if (user == null) return;
                      final claimed = await context
                          .read<GetLeadCubit>()
                          .request(rmName: user.name);
                      if (!context.mounted) return;
                      if (claimed.isNotEmpty) {
                        showCompassSnack(
                          context,
                          message:
                              'Lead${claimed.length == 1 ? '' : 's'} #${claimed.map((l) => l.id).join(', #')} claimed. View in All Leads.',
                          type: CompassSnackType.success,
                        );
                      }
                    }
                  : null,
            ),
          ),
          if (d.totalPoolLeads == 0) ...[
            const SizedBox(height: 10),
            Text(
              'Pool is empty right now. Try again later.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: enabled && value > min
                ? () => onChanged!(value - 1)
                : null,
            icon: const Icon(Icons.remove, size: 18),
            splashRadius: 18,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled && value < max
                ? () => onChanged!(value + 1)
                : null,
            icon: const Icon(Icons.add, size: 18),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _RecentClaims extends StatelessWidget {
  final List<LeadModel> claims;
  const _RecentClaims({required this.claims});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently claimed',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (claims.isEmpty)
          const CompassEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No claims yet',
          )
        else
          ...claims.map((c) => _ClaimRow(lead: c)),
      ],
    );
  }
}

class _ClaimRow extends StatelessWidget {
  final LeadModel lead;
  const _ClaimRow({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              context.push(RouteNames.leadDetailPath(lead.id)),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PiiDisplay.nameFor(lead.fullName, lead.consentStatus),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        lead.source.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
