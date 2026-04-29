import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/get_lead_cubit.dart';

/// Get Lead — RM / TL flow to claim leads from the shared pool.
/// Simplified per the demo-ready spec:
///   • Two KPIs (Total Requested ITD, Total Converted ITD)
///   • Request Form with no weekly cap
///   • Weekly cap banner / recent claims / wrong-contact bonus tiles all
///     retired — they were noise for the actual demo.
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
                      _UserKpis(state: state),
                      const SizedBox(height: 16),
                      _RequestForm(state: state),
                      const SizedBox(height: 16),
                      _PoolHelperLine(state: state),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

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
            label: 'Total Leads Requested',
            value: '${d.leadsRequestedItd}',
            color: AppColors.tealAccent,
            icon: Icons.outbox_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tile(
            label: 'Total Leads Converted',
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

class _RequestForm extends StatelessWidget {
  final GetLeadState state;
  const _RequestForm({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.dashboard!;
    final available = d.totalPoolLeads > 0 && !state.isSubmitting;
    final maxRequestable = d.totalPoolLeads;

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
              label: state.isSubmitting ? 'Requesting…' : 'Request leads',
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
                              'Lead${claimed.length == 1 ? '' : 's'} #${claimed.map((l) => l.id).join(', #')} claimed.',
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

class _PoolHelperLine extends StatelessWidget {
  final GetLeadState state;
  const _PoolHelperLine({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.dashboard?.totalPoolLeads ?? 0;
    return Center(
      child: Text(
        total == 0
            ? 'Pool is empty right now. Try again later.'
            : '$total leads currently available in the shared pool.',
        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
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
