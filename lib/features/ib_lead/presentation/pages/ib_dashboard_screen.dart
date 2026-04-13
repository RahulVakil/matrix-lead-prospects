import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// IB Dashboard — landing screen for the Investment Banking role.
/// Shows IB deal pipeline, pending approvals, recent submissions.
class IbDashboardScreen extends StatefulWidget {
  const IbDashboardScreen({super.key});

  @override
  State<IbDashboardScreen> createState() => _IbDashboardScreenState();
}

class _IbDashboardScreenState extends State<IbDashboardScreen> {
  final _repo = getIt<IbLeadRepository>();
  bool _loading = true;
  List<IbLeadModel> _pending = [];
  List<IbLeadModel> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthCubit>().state.currentUser?.id ?? '';
    // IB role sees all IB leads; other roles see their own
    _all = await _repo.getAllForBranchHead(userId);
    _pending = _all.where((l) => l.status == IbLeadStatus.pending).toList();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    return HeroScaffold(
      header: _IbHeader(name: user?.name ?? 'IB'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navyPrimary,
        onPressed: () => context.push('/ib-leads/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CompassLoader())
          : RefreshIndicator(
              color: AppColors.navyPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                children: [
                  // Summary strip
                  _IbSummaryCard(
                    total: _all.length + _pending.length,
                    pending: _pending.length,
                    approved: _all.where((l) => l.status == IbLeadStatus.approved).length,
                  ),
                  const SizedBox(height: 22),

                  // Quick actions
                  Row(
                    children: [
                      _qa(Icons.fact_check_outlined, 'Pending', AppColors.warmAmber,
                          () => context.push('/ib-leads')),
                      const SizedBox(width: 10),
                      _qa(Icons.business_center_outlined, 'New IB', AppColors.tealAccent,
                          () => context.push('/ib-leads/new')),
                      const SizedBox(width: 10),
                      _qa(Icons.notifications_outlined, 'Alerts', AppColors.coldBlue,
                          () => context.push('/notifications')),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Pending approvals
                  _sectionTitle('Pending review', _pending.length),
                  const SizedBox(height: 12),
                  if (_pending.isEmpty)
                    const CompassEmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No pending IB leads',
                    )
                  else
                    ..._pending.take(5).map((ib) => _IbCard(
                          ib: ib,
                          onTap: () => context.push(RouteNames.ibLeadDetailPath(ib.id)),
                        )),

                  const SizedBox(height: 22),

                  // All IB leads
                  _sectionTitle('All IB deals', _all.length),
                  const SizedBox(height: 12),
                  if (_all.isEmpty)
                    const CompassEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No IB leads yet',
                    )
                  else
                    ..._all.take(10).map((ib) => _IbCard(
                          ib: ib,
                          onTap: () => context.push(RouteNames.ibLeadDetailPath(ib.id)),
                        )),
                ],
              ),
            ),
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
            padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
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
      ],
    );
  }
}

class _IbHeader extends StatelessWidget {
  final String name;
  const _IbHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.fromLTRB(18, topInset + 14, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MATRIX IB',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Investment Banking',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IbSummaryCard extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;

  const _IbSummaryCard({required this.total, required this.pending, required this.approved});

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
      child: Row(
        children: [
          _stat('$total', 'Total deals', Colors.white),
          _divider(),
          _stat('$pending', 'Pending', AppColors.warmAmber),
          _divider(),
          _stat('$approved', 'Approved', AppColors.successGreen),
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
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
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
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.15),
      );
}

class _IbCard extends StatelessWidget {
  final IbLeadModel ib;
  final VoidCallback onTap;

  const _IbCard({required this.ib, required this.onTap});

  Color get _statusColor => switch (ib.status) {
        IbLeadStatus.pending => AppColors.warmAmber,
        IbLeadStatus.approved => AppColors.successGreen,
        IbLeadStatus.sentBack => AppColors.errorRed,
        IbLeadStatus.forwarded => AppColors.tealAccent,
        _ => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ib.companyName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ib.dealType.label} · RM: ${ib.createdByName}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ib.status.label,
                    style: AppTextStyles.caption.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
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
