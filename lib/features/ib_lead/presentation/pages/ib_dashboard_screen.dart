import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/compass_chip.dart';
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

enum _IbSortKey {
  dealSizeDesc('Deal size \u2193'),
  dealSizeAsc('Deal size \u2191'),
  dateNewest('Newest first'),
  dateOldest('Oldest first');

  final String label;
  const _IbSortKey(this.label);
}

enum _TimelineBucket {
  now('Now', 0, 0),
  upTo6M('Up to 6M', 1, 6),
  sixTo12M('6 – 12M', 7, 12),
  overOneYear('1 Year +', 13, 999);

  final String label;
  final int minMonths;
  final int maxMonths;
  const _TimelineBucket(this.label, this.minMonths, this.maxMonths);

  bool contains(int months) => months >= minMonths && months <= maxMonths;
}

class _IbDashboardScreenState extends State<IbDashboardScreen> {
  final _repo = getIt<IbLeadRepository>();
  bool _loading = true;
  List<IbLeadModel> _all = [];

  _IbSortKey _sortKey = _IbSortKey.dateNewest;
  final Set<IbDealType> _filterTypes = {};
  final Set<IbDealStage> _filterStages = {};
  final Set<IbDealValueRange> _filterSizes = {};
  final Set<_TimelineBucket> _filterTimelines = {};
  bool _filtersExpanded = false;

  double _sizeOf(IbLeadModel l) =>
      l.dealValue ?? (l.dealValueRange.minValue + l.dealValueRange.maxValue) / 2;

  List<IbLeadModel> _applyFiltersAndSort(List<IbLeadModel> input) {
    var list = input.where((l) {
      if (_filterTypes.isNotEmpty && !_filterTypes.contains(l.dealType)) {
        return false;
      }
      if (_filterStages.isNotEmpty) {
        if (l.dealStage == null || !_filterStages.contains(l.dealStage)) {
          return false;
        }
      }
      if (_filterSizes.isNotEmpty && !_filterSizes.contains(l.dealValueRange)) {
        return false;
      }
      if (_filterTimelines.isNotEmpty) {
        if (l.timelineMonths == null) return false;
        final any = _filterTimelines.any((b) => b.contains(l.timelineMonths!));
        if (!any) return false;
      }
      return true;
    }).toList();

    switch (_sortKey) {
      case _IbSortKey.dealSizeDesc:
        list.sort((a, b) => _sizeOf(b).compareTo(_sizeOf(a)));
        break;
      case _IbSortKey.dealSizeAsc:
        list.sort((a, b) => _sizeOf(a).compareTo(_sizeOf(b)));
        break;
      case _IbSortKey.dateNewest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _IbSortKey.dateOldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    return list;
  }

  bool get _hasAnyFilter =>
      _filterTypes.isNotEmpty ||
      _filterStages.isNotEmpty ||
      _filterSizes.isNotEmpty ||
      _filterTimelines.isNotEmpty;

  void _clearFilters() => setState(() {
        _filterTypes.clear();
        _filterStages.clear();
        _filterSizes.clear();
        _filterTimelines.clear();
      });

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthCubit>().state.currentUser?.id ?? '';
    final raw = await _repo.getAllForBranchHead(userId);
    // IB user only sees Approved leads — under-review leads stay with Admin/MIS.
    _all = raw.where((l) => l.status.isApproved).toList();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    return HeroScaffold(
      header: _IbHeader(name: user?.name ?? 'IB'),
      body: _loading
          ? const Center(child: CompassLoader())
          : RefreshIndicator(
              color: AppColors.navyPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                children: [
                  // Summary strip — shows Total Leads + Approved (Pending bucket
                  // belongs to Admin/MIS, IB never sees in-review leads).
                  _IbSummaryCard(
                    total: _all.length,
                    approved: _all.where((l) => l.status.isApproved).length,
                  ),
                  const SizedBox(height: 22),

                  // All IB leads — with sort + filter
                  _sectionTitle('All IB leads', _applyFiltersAndSort(_all).length),
                  const SizedBox(height: 10),
                  _buildSortFilterBar(),
                  if (_filtersExpanded) ...[
                    const SizedBox(height: 10),
                    _buildFilterPanel(),
                  ],
                  const SizedBox(height: 12),
                  Builder(builder: (_) {
                    final list = _applyFiltersAndSort(_all);
                    if (list.isEmpty) {
                      return CompassEmptyState(
                        icon: Icons.inbox_outlined,
                        title: _hasAnyFilter
                            ? 'No deals match your filters'
                            : 'No IB leads yet',
                      );
                    }
                    return Column(
                      children: list
                          .take(50)
                          .map((ib) => _IbCard(
                                ib: ib,
                                onTap: () => context
                                    .push(RouteNames.ibLeadDetailPath(ib.id)),
                              ))
                          .toList(),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildSortFilterBar() {
    final activeFilterCount = _filterTypes.length +
        _filterStages.length +
        _filterSizes.length +
        _filterTimelines.length;
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeFilterCount > 0
                        ? AppColors.navyPrimary.withValues(alpha: 0.4)
                        : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune,
                        size: 16,
                        color: activeFilterCount > 0
                            ? AppColors.navyPrimary
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      activeFilterCount > 0
                          ? 'Filters  $activeFilterCount'
                          : 'Filter',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: activeFilterCount > 0
                            ? AppColors.navyPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _filtersExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<_IbSortKey>(
          initialValue: _sortKey,
          onSelected: (k) => setState(() => _sortKey = k),
          itemBuilder: (_) => _IbSortKey.values
              .map((k) => PopupMenuItem(value: k, child: Text(k.label)))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _sortKey.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterGroup(
            'Deal type',
            IbDealType.values
                .map((t) => _toggleChip(
                      label: t.label,
                      selected: _filterTypes.contains(t),
                      onTap: () => setState(() => _filterTypes.contains(t)
                          ? _filterTypes.remove(t)
                          : _filterTypes.add(t)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _filterGroup(
            'Deal stage',
            IbDealStage.values
                .map((s) => _toggleChip(
                      label: s.label,
                      selected: _filterStages.contains(s),
                      onTap: () => setState(() => _filterStages.contains(s)
                          ? _filterStages.remove(s)
                          : _filterStages.add(s)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _filterGroup(
            'Deal size',
            IbDealValueRange.values
                .map((r) => _toggleChip(
                      label: r.label,
                      selected: _filterSizes.contains(r),
                      onTap: () => setState(() => _filterSizes.contains(r)
                          ? _filterSizes.remove(r)
                          : _filterSizes.add(r)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _filterGroup(
            'Timeline',
            _TimelineBucket.values
                .map((b) => _toggleChip(
                      label: b.label,
                      selected: _filterTimelines.contains(b),
                      onTap: () => setState(() => _filterTimelines.contains(b)
                          ? _filterTimelines.remove(b)
                          : _filterTimelines.add(b)),
                    ))
                .toList(),
          ),
          if (_hasAnyFilter)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.navyPrimary,
                ),
                child: const Text('Clear all'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterGroup(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ],
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return CompassFilterChip(selected: selected, label: label, onTap: onTap);
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
  final int approved;

  const _IbSummaryCard({required this.total, required this.approved});

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
          _stat('$total', 'Total Leads', Colors.white),
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
        IbLeadStatus.forwarded => AppColors.successGreen,
        IbLeadStatus.draft => AppColors.warmAmber,
        IbLeadStatus.dropped => AppColors.dormantGray,
      };

  Color get _tempColor => switch (ib.temperature) {
        IbLeadTemperature.hot => AppColors.errorRed,
        IbLeadTemperature.warm => AppColors.warmAmber,
        IbLeadTemperature.cold => AppColors.coldBlue,
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
                  height: 48,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ib.companyName,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _tempColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _tempColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: _tempColor,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ib.temperature.label,
                                  style: AppTextStyles.caption.copyWith(
                                    color: _tempColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ib.dealValue != null
                            ? IndianCurrencyFormatter.shortForm(ib.dealValue!)
                            : ib.dealValueRange.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.navyPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
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
