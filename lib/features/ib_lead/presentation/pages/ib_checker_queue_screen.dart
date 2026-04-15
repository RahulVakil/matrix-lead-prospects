import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class IbCheckerQueueScreen extends StatefulWidget {
  const IbCheckerQueueScreen({super.key});

  @override
  State<IbCheckerQueueScreen> createState() => _IbCheckerQueueScreenState();
}

class _IbCheckerQueueScreenState extends State<IbCheckerQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final IbLeadRepository _repo = getIt<IbLeadRepository>();
  bool _isLoading = true;
  List<IbLeadModel> _all = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    final all = await _repo.getAllForBranchHead(user.id);
    if (!mounted) return;
    setState(() {
      _all = all;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _all.where((l) => l.status.isAwaitingReview).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: CompassAppBar(
        title: 'IB Lead Approvals',
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.textOnDark,
          unselectedLabelColor: AppColors.textOnDark.withValues(alpha: 0.6),
          indicatorColor: AppColors.textOnDark,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'All (${_all.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const CompassLoader()
          : TabBarView(
              controller: _tab,
              children: [
                _list(pending, emptyTitle: 'No pending submissions'),
                _list(_all, emptyTitle: 'No IB leads yet'),
              ],
            ),
    );
  }

  Widget _list(List<IbLeadModel> list, {required String emptyTitle}) {
    if (list.isEmpty) {
      return CompassEmptyState(icon: Icons.business_center, title: emptyTitle);
    }
    return RefreshIndicator(
      color: AppColors.navyPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _IbLeadCard(
          lead: list[i],
          onTap: () async {
            await context.push('/ib-leads/${list[i].id}');
            _load();
          },
        ),
      ),
    );
  }
}

class _IbLeadCard extends StatelessWidget {
  final IbLeadModel lead;
  final VoidCallback onTap;
  const _IbLeadCard({required this.lead, required this.onTap});

  Color get _statusColor => switch (lead.status) {
        IbLeadStatus.pending => AppColors.warmAmber,
        IbLeadStatus.approved => AppColors.successGreen,
        IbLeadStatus.sentBack => AppColors.errorRed,
        IbLeadStatus.forwarded => AppColors.successGreen,
        IbLeadStatus.draft => AppColors.warmAmber,
        IbLeadStatus.dropped => AppColors.dormantGray,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CompassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(lead.companyName, style: AppTextStyles.labelLarge),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lead.status.label,
                    style: AppTextStyles.caption.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${lead.dealType.label}  ·  ${lead.dealValueRange.label}  ·  ${lead.dealStage?.label ?? "—"}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${lead.createdByName}  ·  ${(lead.submittedAt ?? lead.createdAt).day}/${(lead.submittedAt ?? lead.createdAt).month}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
