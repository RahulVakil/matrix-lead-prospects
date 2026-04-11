import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/get_lead_cubit.dart';

/// Get Lead — RM-only flow to claim a fresh lead from the shared pool.
/// Pool status, filters, preview-and-claim cadence, recent claims, and an
/// empty pool fallback. Replaces the old toast-only RequestLeadsScreen.
class GetLeadScreen extends StatelessWidget {
  const GetLeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetLeadCubit()..init(),
      child: const _GetLeadBody(),
    );
  }
}

class _GetLeadBody extends StatelessWidget {
  const _GetLeadBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetLeadCubit, GetLeadState>(
      builder: (context, state) {
        return HeroScaffold(
          header: HeroAppBar.simple(
            title: 'Get a lead',
            subtitle: 'Claim from the shared pool',
          ),
          body: state.isLoading
              ? const Center(child: CompassLoader())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    _PoolStatusCard(
                      total: state.totalAvailable,
                      filtered: state.filteredAvailable,
                      breakdown: state.breakdown,
                      hasFilters: state.filters.vertical != null ||
                          state.filters.aumBand != null ||
                          state.filters.source != null,
                    ),
                    const SizedBox(height: 18),
                    _FiltersBlock(filters: state.filters),
                    const SizedBox(height: 18),
                    _PreviewArea(state: state),
                    if (state.recentClaims.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _RecentClaims(claims: state.recentClaims),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Pool status card — hero number + breakdown
// ────────────────────────────────────────────────────────────────────

class _PoolStatusCard extends StatelessWidget {
  final int total;
  final int filtered;
  final Map<String, int> breakdown;
  final bool hasFilters;

  const _PoolStatusCard({
    required this.total,
    required this.filtered,
    required this.breakdown,
    required this.hasFilters,
  });

  @override
  Widget build(BuildContext context) {
    final ewg = breakdown['EWG'] ?? 0;
    final pwg = breakdown['PWG'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AVAILABLE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$filtered',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        height: 1.0,
                      ),
                    ),
                    if (hasFilters && filtered != total)
                      TextSpan(
                        text: ' / $total',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniRow('EWG', ewg, AppColors.tealAccent),
              const SizedBox(height: 6),
              _miniRow('PWG', pwg, AppColors.navyPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label · $value',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Filters block — three horizontal scroll groups
// ────────────────────────────────────────────────────────────────────

class _FiltersBlock extends StatelessWidget {
  final GetLeadFilters filters;
  const _FiltersBlock({required this.filters});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GetLeadCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Vertical'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _chip(context, label: 'Any', selected: filters.vertical == null,
                onTap: () => cubit.setVertical(null)),
            _chip(context, label: 'EWG', selected: filters.vertical == 'EWG',
                onTap: () => cubit.setVertical('EWG')),
            _chip(context, label: 'PWG', selected: filters.vertical == 'PWG',
                onTap: () => cubit.setVertical('PWG')),
          ],
        ),
        const SizedBox(height: 14),
        _label('AUM band'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(context, label: 'Any', selected: filters.aumBand == null,
                onTap: () => cubit.setAum(null)),
            _chip(context, label: '<10L', selected: filters.aumBand == '<10L',
                onTap: () => cubit.setAum('<10L')),
            _chip(context, label: '10-50L', selected: filters.aumBand == '10-50L',
                onTap: () => cubit.setAum('10-50L')),
            _chip(context, label: '50L-1Cr', selected: filters.aumBand == '50L-1Cr',
                onTap: () => cubit.setAum('50L-1Cr')),
            _chip(context, label: '1Cr+', selected: filters.aumBand == '1Cr+',
                onTap: () => cubit.setAum('1Cr+')),
          ],
        ),
        const SizedBox(height: 14),
        _label('Source'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(context, label: 'Any', selected: filters.source == null,
                onTap: () => cubit.setSource(null)),
            ...LeadSource.values.take(5).map(
                  (s) => _chip(
                    context,
                    label: s.label,
                    selected: filters.source == s.label,
                    onTap: () => cubit.setSource(s.label),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _chip(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    return CompassFilterChip(selected: selected, label: label, onTap: onTap);
  }
}

// ────────────────────────────────────────────────────────────────────
// Preview area — empty / loaded / no-match states
// ────────────────────────────────────────────────────────────────────

class _PreviewArea extends StatelessWidget {
  final GetLeadState state;
  const _PreviewArea({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.preview == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
        ),
        child: const CompassEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No matching leads',
          subtitle: 'Adjust the filters above to widen the search.',
        ),
      );
    }
    return _PreviewCard(lead: state.preview!);
  }
}

class _PreviewCard extends StatelessWidget {
  final LeadModel lead;
  const _PreviewCard({required this.lead});

  String get _obfuscatedName {
    final parts = lead.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first} ${parts.last[0]}.';
    }
    return parts.first;
  }

  String get _initials {
    final parts = lead.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return lead.fullName.substring(0, lead.fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyPrimary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT FROM POOL',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.tealAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.navyPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _obfuscatedName,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.companyName ?? '—',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _factChip(Icons.work_outline, lead.vertical),
              _factChip(Icons.source_outlined, lead.source.label),
              if (lead.estimatedAum != null)
                _factChip(Icons.bolt_outlined, lead.aumDisplay),
              if (lead.city != null) _factChip(Icons.location_on_outlined, lead.city!),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CompassButton.secondary(
                  label: 'Skip',
                  icon: Icons.skip_next,
                  onPressed: () => context.read<GetLeadCubit>().skip(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CompassButton(
                  label: 'Claim this lead',
                  icon: Icons.check,
                  onPressed: () async {
                    final user = context.read<AuthCubit>().state.currentUser;
                    if (user == null) return;
                    final claimed = await context
                        .read<GetLeadCubit>()
                        .claim(rmId: user.id, rmName: user.name);
                    if (claimed != null && context.mounted) {
                      showCompassSnack(
                        context,
                        message: 'Lead claimed',
                        type: CompassSnackType.success,
                      );
                      context.push(RouteNames.leadDetailPath(claimed.id));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _factChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Recent claims
// ────────────────────────────────────────────────────────────────────

class _RecentClaims extends StatelessWidget {
  final List<LeadModel> claims;
  const _RecentClaims({required this.claims});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR RECENT CLAIMS',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: List.generate(claims.length, (i) {
              final lead = claims[i];
              final isLast = i == claims.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () =>
                        context.push(RouteNames.leadDetailPath(lead.id)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.successGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lead.fullName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            lead.vertical,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textHint, size: 16),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 42),
                      color: AppColors.borderDefault.withValues(alpha: 0.4),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
