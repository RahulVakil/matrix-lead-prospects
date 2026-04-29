import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/lead_request.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/get_lead_cubit.dart';

/// Get Lead — RM / TL flow to request leads from the shared pool.
///
/// Workflow change in this batch:
///   - RM SUBMITS A REQUEST (no auto-claim). The request lands in Admin /
///     MIS's Manage Pool → Requests tab.
///   - On submit, RM + their TL each receive an in-app + email
///     notification ("Request raised — you will be notified once leads
///     are mapped").
///   - When Admin assigns leads, both RM + TL receive a second
///     notification with the assigned-leads list and the assignment date.
///
/// Pool-size references are intentionally absent. The request history
/// section is the durable surface — RM sees their own; TL sees their team.
class GetLeadScreen extends StatelessWidget {
  const GetLeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => GetLeadCubit(viewer: user)..init(),
      child: _GetLeadBody(viewerRole: user.role),
    );
  }
}

class _GetLeadBody extends StatelessWidget {
  final UserRole viewerRole;
  const _GetLeadBody({required this.viewerRole});

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
            subtitle: viewerRole == UserRole.teamLead
                ? 'Team requests · audit trail'
                : 'Submit a request to Admin / MIS',
          ),
          body: state.isLoading
              ? const Center(child: CompassLoader())
              : RefreshIndicator(
                  color: AppColors.navyPrimary,
                  onRefresh: () => context.read<GetLeadCubit>().init(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _UserKpis(state: state),
                      const SizedBox(height: 16),
                      // TLs see the audit trail but don't submit requests
                      // themselves through this screen — RMs do that.
                      if (viewerRole != UserRole.teamLead) ...[
                        _RequestForm(state: state),
                        const SizedBox(height: 16),
                      ],
                      _RequestHistory(
                        requests: state.requests,
                        viewerRole: viewerRole,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ── KPI tiles ────────────────────────────────────────────────────────

class _UserKpis extends StatelessWidget {
  final GetLeadState state;
  const _UserKpis({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.dashboard!;
    return Row(
      children: [
        Expanded(
          child: _Tile(
            label: 'Total Leads Requested (ITD - Inception Till Date)',
            value: '${d.leadsRequestedItd}',
            color: AppColors.tealAccent,
            icon: Icons.outbox_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tile(
            label: 'Total Leads Converted (ITD - Inception Till Date)',
            value: '${d.poolLeadsConvertedItd}',
            color: AppColors.successGreen,
            icon: Icons.verified_outlined,
          ),
        ),
      ],
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}

// ── Request form ─────────────────────────────────────────────────────

class _RequestForm extends StatelessWidget {
  final GetLeadState state;
  const _RequestForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final available = !state.isSubmitting;

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
                max: 50,
                onChanged: available
                    ? (v) =>
                        context.read<GetLeadCubit>().setRequestedCount(v)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Request ${state.requestedCount} ${state.requestedCount == 1 ? "lead" : "leads"}.',
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
              label: state.isSubmitting ? 'Submitting…' : 'Request leads',
              isLoading: state.isSubmitting,
              onPressed: available && state.requestedCount > 0
                  ? () async {
                      final ok = await context
                          .read<GetLeadCubit>()
                          .submitRequest();
                      if (!context.mounted) return;
                      if (ok) {
                        showCompassSnack(
                          context,
                          message:
                              'Request submitted. Admin will assign leads.',
                          type: CompassSnackType.success,
                        );
                      }
                    }
                  : null,
            ),
          ),
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
            onPressed:
                enabled && value > min ? () => onChanged!(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
            splashRadius: 18,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed:
                enabled && value < max ? () => onChanged!(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ── Request history (audit trail) ────────────────────────────────────

class _RequestHistory extends StatelessWidget {
  final List<LeadRequest> requests;
  final UserRole viewerRole;
  const _RequestHistory({required this.requests, required this.viewerRole});

  @override
  Widget build(BuildContext context) {
    final isTl = viewerRole == UserRole.teamLead;
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
            isTl ? 'Team request history' : 'Request history',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (requests.isEmpty)
            Text(
              isTl
                  ? 'No requests from your team yet.'
                  : 'You haven\'t submitted any requests yet.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
            )
          else
            ...requests.map((r) => _RequestRow(req: r, isTl: isTl)),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final LeadRequest req;
  final bool isTl;
  const _RequestRow({required this.req, required this.isTl});

  Color get _statusColor {
    switch (req.status) {
      case LeadRequestStatus.pending:
        return AppColors.warmAmber;
      case LeadRequestStatus.fulfilled:
        return AppColors.successGreen;
      case LeadRequestStatus.cancelled:
        return AppColors.dormantGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${req.createdAt.day}/${req.createdAt.month}';
    final fulfilledStr = req.fulfilledAt == null
        ? null
        : '${req.fulfilledAt!.day}/${req.fulfilledAt!.month}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isTl) ...[
                Text(
                  '${req.rmName} · ',
                  style: AppTextStyles.labelLarge
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
              Text(
                '${req.requestedCount} ${req.requestedCount == 1 ? "lead" : "leads"} requested',
                style: AppTextStyles.labelLarge
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  req.status.label,
                  style: AppTextStyles.caption.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Raised on $dateStr'
            '${fulfilledStr != null ? "  ·  Assigned on $fulfilledStr" : ""}'
            '${req.fulfilledByAdminName != null ? " by ${req.fulfilledByAdminName}" : ""}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          if (req.assignedLeadIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: req.assignedLeadIds
                  .map(
                    (id) => InkWell(
                      onTap: () =>
                          context.push(RouteNames.leadDetailPath(id)),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTertiary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Text(
                          '#$id',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.navyPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
