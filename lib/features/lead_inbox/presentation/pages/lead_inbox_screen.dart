import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../leads_dashboard/presentation/widgets/leads_add_sheet.dart';
import '../../../matrix_home/presentation/widgets/lead_status_pill.dart';
import '../../../matrix_home/presentation/widgets/leads_hero_card.dart';
import '../cubit/lead_inbox_cubit.dart';

/// All Leads listing — mobile-first, clean filter sheet, status pill.
/// Optional initial filters can be passed via route extras (used by the
/// Leadership Dashboard's clickable KPI tiles to open a pre-filtered view).
class LeadInboxScreen extends StatelessWidget {
  /// Pre-applied Status filter (Hot / Warm / Cold / Onboarded). The user
  /// can still change it via the filter sheet.
  final LeadTemperature? initialStatus;
  final LeadSource? initialSource;
  /// When true, the inbox excludes Dropped + Onboarded stages — matches
  /// the Leadership "Total leads" KPI tile semantics.
  final bool initialActiveOnly;
  final String? titleOverride;
  /// When true, render the LeadsHeroCard (KPI hero with Hot/Warm/Cold +
  /// conversion) above the All-leads list. Used by the /leads-dashboard
  /// entry so the user lands on the list directly with the dashboard
  /// summary on top — saves a click vs a separate dashboard screen.
  final bool showHero;
  /// Pre-applied lifecycle stage filter (Lead / Profiling / Engage /
  /// Onboard / Dropped). Driven by the home Leads pipeline list rows.
  final LeadStage? initialLifecycle;
  /// Reassignment filter — 'to_me' or 'away'.
  final String? initialReassignment;
  /// TL-view: when set, the Leads dashboard renders someone else's
  /// pipeline. Shows a banner + hides the FAB so the TL can't create on
  /// the RM's behalf.
  final String? rmIdOverride;
  final String? rmNameOverride;

  const LeadInboxScreen({
    super.key,
    this.initialStatus,
    this.initialSource,
    this.initialActiveOnly = false,
    this.titleOverride,
    this.showHero = false,
    this.initialLifecycle,
    this.initialReassignment,
    this.rmIdOverride,
    this.rmNameOverride,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => LeadInboxCubit(
        rmId: rmIdOverride ?? user.id,
        initialStatus: initialStatus,
        initialSource: initialSource,
        initialActiveOnly: initialActiveOnly,
        initialLifecycle: initialLifecycle,
        initialReassignment: initialReassignment,
      )..loadLeads(refresh: true),
      child: _InboxBody(
        titleOverride: titleOverride,
        showHero: showHero,
        viewingRmName: rmNameOverride,
      ),
    );
  }
}

class _InboxBody extends StatefulWidget {
  final String? titleOverride;
  final bool showHero;
  /// When set, the screen is rendering this RM's pipeline for a TL viewer.
  /// Drives the "Viewing X's pipeline" banner + hides the FAB.
  final String? viewingRmName;
  const _InboxBody({
    this.titleOverride,
    this.showHero = false,
    this.viewingRmName,
  });

  @override
  State<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<_InboxBody> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadInboxCubit, LeadInboxState>(
      builder: (context, state) {
        final cubit = context.read<LeadInboxCubit>();
        final activeFilterCount =
            (state.statusFilter != null ? 1 : 0) +
            (state.ibLinkedOnly ? 1 : 0) +
            (state.myLeadsOnly ? 1 : 0);

        // Visible count after all filters (lifecycle / reassignment /
        // search / status). state.totalCount is the unfiltered repo total
        // and would mislead the header when a filter is applied.
        final visibleCount = state.leads.length;

        final isTlView = widget.viewingRmName != null;
        return HeroScaffold(
          header: HeroAppBar.simple(
              title: isTlView
                  ? '${widget.viewingRmName}\'s pipeline'
                  : (widget.titleOverride ??
                      (widget.showHero ? 'Leads' : 'All leads')),
              subtitle: widget.showHero ? null : '$visibleCount total'),
          // FAB hidden in TL-view — TL can't create on the RM's behalf.
          floatingActionButton: isTlView
              ? null
              : FloatingActionButton(
                  backgroundColor: AppColors.navyPrimary,
                  shape: const CircleBorder(),
                  onPressed: () => LeadsAddSheet.show(context),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.navyPrimary))
              : RefreshIndicator(
                  color: AppColors.navyPrimary,
                  onRefresh: () => cubit.loadLeads(refresh: true),
                  child: _ScrollableBody(
                    leads: state.leads,
                    state: state,
                    cubit: cubit,
                    showHero: widget.showHero,
                    activeFilterCount: activeFilterCount,
                    titleOverride: widget.titleOverride,
                    viewingRmName: widget.viewingRmName,
                    onFilterTap: () => _showFilterSheet(context, state, cubit),
                    onSearchClear: () {
                      _searchCtrl.clear();
                      cubit.search('');
                    },
                    searchCtrl: _searchCtrl,
                  ),
                ),
        );
      },
    );
  }

  void _showFilterSheet(
    BuildContext ctx,
    LeadInboxState state,
    LeadInboxCubit cubit,
  ) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheetBody(
        initialStatus: state.statusFilter,
        initialIbOnly: state.ibLinkedOnly,
        initialMyOnly: state.myLeadsOnly,
        showMyLeadsToggle: context.read<AuthCubit>().state.currentUser?.role == UserRole.teamLead,
        onApply: (status, ibOnly, myOnly) {
          cubit.setStatusFilter(status);
          cubit.setIbLinkedOnly(ibOnly);
          cubit.setMyLeadsOnly(myOnly);
        },
      ),
    );
  }
}

/// One scrollable body — hero (when shown), section row with inline
/// filter/sort, compact search, and the lead list. All scroll together so
/// the hero/search/filter scroll away as the user scrolls the list,
/// leaving the lead cards in full view.
class _ScrollableBody extends StatelessWidget {
  final List<LeadModel> leads;
  final LeadInboxState state;
  final LeadInboxCubit cubit;
  final bool showHero;
  final int activeFilterCount;
  final String? titleOverride;
  final String? viewingRmName;
  final VoidCallback onFilterTap;
  final VoidCallback onSearchClear;
  final TextEditingController searchCtrl;

  const _ScrollableBody({
    required this.leads,
    required this.state,
    required this.cubit,
    required this.showHero,
    required this.activeFilterCount,
    this.titleOverride,
    this.viewingRmName,
    required this.onFilterTap,
    required this.onSearchClear,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    // Index map (with optional TL-view banner at the very top):
    //   0 → TL-view banner (only when viewingRmName != null)
    //   1 → hero (only when showHero)
    //   2 → section header row (title + filter pill + sort)
    //   3 → search field
    //   4 → divider
    //   5..N → lead cards (or empty state)
    final hasBanner = viewingRmName != null;
    final headerCount =
        (hasBanner ? 1 : 0) + (showHero ? 1 : 0) + 3; // section + search + divider
    final hasEmpty = leads.isEmpty;
    final itemCount = headerCount + (hasEmpty ? 1 : leads.length);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
      itemCount: itemCount,
      itemBuilder: (_, index) {
        final user = context.read<AuthCubit>().state.currentUser;
        final isTl = user?.role == UserRole.teamLead;

        // 0 — TL-view banner
        if (hasBanner && index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: _TlViewBanner(rmName: viewingRmName!),
          );
        }
        final bannerAdj = hasBanner ? 1 : 0;

        if (showHero && index == bannerAdj) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: LeadsHeroCard(
              active: 12,
              dropped: 3,
              onboarded: 8,
              funnelTotal: 23,
              hot: 4,
              warm: 5,
              cold: 3,
            ),
          );
        }

        final adj = bannerAdj + (showHero ? 1 : 0);

        if (index == adj) {
          // Section header — labels reflect the active filter (titleOverride
          // when set; otherwise "All leads"). Count is the visible-after-
          // filter list length, not the unfiltered repo total.
          final headerLabel = titleOverride ?? 'All leads';
          final visibleCount = leads.length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 6),
            child: Row(
              children: [
                Text(
                  headerLabel,
                  style: AppTextStyles.heading3.copyWith(
                    color: const Color(0xFF0A1629),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$visibleCount total',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const Spacer(),
                _FilterPill(
                  count: activeFilterCount,
                  onTap: onFilterTap,
                ),
                const SizedBox(width: 8),
                _SortDropdown(
                  value: state.sortBy ?? 'name',
                  onChanged: (v) => cubit.setSort(v),
                ),
              ],
            ),
          );
        }

        if (index == adj + 1) {
          // Compact search field
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: searchCtrl,
                onChanged: cubit.search,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search the list…',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: AppColors.textMuted),
                  prefixIconConstraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  filled: true,
                  fillColor: AppColors.surfaceTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.navyPrimary, width: 1.2),
                  ),
                  suffixIcon: (state.searchQuery ?? '').isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          onPressed: onSearchClear,
                          splashRadius: 14,
                          tooltip: 'Clear search',
                        ),
                ),
              ),
            ),
          );
        }

        if (index == adj + 2) {
          return const Divider(height: 1);
        }

        if (hasEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 44, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    (state.searchQuery ?? '').isNotEmpty
                        ? "No leads matching '${state.searchQuery}'"
                        : 'No leads match',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      searchCtrl.clear();
                      cubit.setStatusFilter(null);
                      cubit.setIbLinkedOnly(false);
                      cubit.search('');
                    },
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          );
        }

        final leadIndex = index - headerCount;
        final lead = leads[leadIndex];
        final showDate = state.sortBy == 'created_desc' ||
            state.sortBy == 'created_asc';
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: _LeadCard(
            lead: lead,
            showCreatedDate: showDate,
            isMyLead: isTl && lead.assignedRmId == user?.id,
            highlightQuery: state.searchQuery,
            onTap: () =>
                context.push(RouteNames.leadDetailPath(lead.id)),
          ),
        );
      },
    );
  }
}

class _TlViewBanner extends StatelessWidget {
  final String rmName;
  const _TlViewBanner({required this.rmName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warmAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 16, color: AppColors.warmAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Viewing $rmName's pipeline · read-only",
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF8A4F00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.navyPrimary.withValues(alpha: 0.1)
              : AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.navyPrimary.withValues(alpha: 0.4)
                : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune,
                size: 13,
                color: active
                    ? AppColors.navyPrimary
                    : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              active ? 'Filter $count' : 'Filter',
              style: AppTextStyles.labelSmall.copyWith(
                color: active
                    ? AppColors.navyPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      isDense: true,
      icon: const Icon(Icons.sort, size: 14, color: AppColors.navyPrimary),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.navyPrimary,
        fontSize: 11,
      ),
      items: const [
        DropdownMenuItem(value: 'name', child: Text('A–Z')),
        DropdownMenuItem(value: 'created_desc', child: Text('Latest')),
        DropdownMenuItem(value: 'created_asc', child: Text('Oldest')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _FilterSheetBody extends StatefulWidget {
  final LeadTemperature? initialStatus;
  final bool initialIbOnly;
  final bool initialMyOnly;
  final bool showMyLeadsToggle;
  final void Function(LeadTemperature? status, bool ibOnly, bool myOnly)
      onApply;

  const _FilterSheetBody({
    required this.initialStatus,
    required this.initialIbOnly,
    required this.initialMyOnly,
    required this.showMyLeadsToggle,
    required this.onApply,
  });

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late LeadTemperature? _statusF;
  late bool _ibOnly;
  late bool _myOnly;

  @override
  void initState() {
    super.initState();
    _statusF = widget.initialStatus;
    _ibOnly = widget.initialIbOnly;
    _myOnly = widget.initialMyOnly;
  }

  /// User-facing 4-bucket Status filter — Hot / Warm / Cold / Onboarded.
  /// Dormant is intentionally excluded from the picker (it's an edge state
  /// driven by stage transitions, not a normal filter target).
  static const _statuses = [
    LeadTemperature.hot,
    LeadTemperature.warm,
    LeadTemperature.cold,
    LeadTemperature.onboarded,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Filter leads',
                    style: AppTextStyles.heading3
                        .copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _statusF = null;
                    _ibOnly = false;
                    _myOnly = false;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Status',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CompassChoiceChip<LeadTemperature?>(
                  value: null,
                  groupValue: _statusF,
                  label: 'All',
                  onSelected: (_) => setState(() => _statusF = null),
                ),
                ..._statuses.map((s) => CompassChoiceChip<LeadTemperature?>(
                      value: s,
                      groupValue: _statusF,
                      label: s.label,
                      color: s.color,
                      onSelected: (v) => setState(() => _statusF = v),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Show only IB-linked leads',
                      style: AppTextStyles.bodySmall),
                ),
                Switch(
                  value: _ibOnly,
                  activeColor: AppColors.navyPrimary,
                  onChanged: (v) => setState(() => _ibOnly = v),
                ),
              ],
            ),
            if (widget.showMyLeadsToggle) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Show only my leads',
                        style: AppTextStyles.bodySmall),
                  ),
                  Switch(
                    value: _myOnly,
                    activeColor: AppColors.navyPrimary,
                    onChanged: (v) => setState(() => _myOnly = v),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onApply(_statusF, _ibOnly, _myOnly);
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Lead card (#10) — Name + Source + Lifecycle pill + Reassignment pill
// ─────────────────────────────────────────────────────────────────────

/// Maps the prototype's existing [LeadStage] enum to the agreed Wealth-CRM
/// dashboard status set used on lead-card pills.
LeadDashStatus _toLeadDashStatus(LeadStage stage) {
  switch (stage) {
    case LeadStage.lead:
      return LeadDashStatus.lead;
    case LeadStage.profiling:
      return LeadDashStatus.ibPending;
    case LeadStage.engage:
      return LeadDashStatus.contacted;
    case LeadStage.onboard:
      return LeadDashStatus.onboarded;
    case LeadStage.dropped:
    case LeadStage.lostCompetitor:
    case LeadStage.lostNotInterested:
    case LeadStage.lostTiming:
      return LeadDashStatus.dropped;
    case LeadStage.parked:
    case LeadStage.dormant:
      return LeadDashStatus.contacted;
  }
}

/// Mock — production: derive from `previousAssignedRmId == viewer.rmId`
/// AND `reassignedAt` within 7 days (per the Reassignment ticket).
bool _isReassignedToMe(String leadId) {
  // Two lead IDs hard-mocked so the pill is visible in the demo.
  const reassignedIds = {'lead_002', 'lead_005'};
  return reassignedIds.contains(leadId);
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final bool showCreatedDate;
  final bool isMyLead; // TL-2: badge when TL created this lead
  final String? highlightQuery;

  const _LeadCard({
    required this.lead,
    required this.onTap,
    this.showCreatedDate = false,
    this.isMyLead = false,
    this.highlightQuery,
  });

  /// Smart-search highlight (#2): wrap matched substring in a soft yellow
  /// background + bold. Case-insensitive.
  TextSpan _highlightedName(String name, TextStyle baseStyle) {
    final q = (highlightQuery ?? '').trim();
    if (q.isEmpty) return TextSpan(text: name, style: baseStyle);
    final lowerName = name.toLowerCase();
    final lowerQ = q.toLowerCase();
    final idx = lowerName.indexOf(lowerQ);
    if (idx < 0) return TextSpan(text: name, style: baseStyle);
    final before = name.substring(0, idx);
    final match = name.substring(idx, idx + q.length);
    final after = name.substring(idx + q.length);
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: before),
        TextSpan(
          text: match,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            backgroundColor: AppColors.warmAmber.withValues(alpha: 0.22),
          ),
        ),
        TextSpan(text: after),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // RM-facing listings show Temperature (Hot / Warm / Cold) only — Lead
    // Status (stage) was retired in the demo-readiness batch. Stage still
    // drives internal pipeline math but isn't surfaced on cards.
    final temp = lead.temperature;
    final ragColor = temp.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.borderDefault.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                // Left bar colored by stage-RAG
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ragColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name (with smart-search highlight #2)
                      Text.rich(
                        _highlightedName(
                          PiiDisplay.nameFor(
                              lead.fullName, lead.consentStatus),
                          AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Source + optional created date + My Lead badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              showCreatedDate
                                  ? '${lead.source.label} · ${lead.createdAt.day}/${lead.createdAt.month}/${lead.createdAt.year}'
                                  : lead.source.label,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textHint),
                            ),
                          ),
                          if (isMyLead) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.tealAccent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'My Lead',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.tealAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // RM tagging — surfaced on every card so leadership
                      // (TL / Regional / Zonal / CEO / Admin) can see who
                      // owns each lead at a glance when they drill from a
                      // KPI tile into a filtered list.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'RM: ${lead.assignedRmName}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Lifecycle status + reassignment pill + supporting badges
                // (right-aligned column). Lifecycle stage is the primary
                // signal; temperature and assignment context sit below.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Lifecycle stage pill — uses the agreed Wealth-CRM
                    // statuses (Lead / Contacted / IB Pending / IB Approved /
                    // Onboarded / Dropped).
                    LeadStatusPill(
                      status: _toLeadDashStatus(lead.stage),
                      dense: true,
                    ),
                    // Reassignment pill (computed per viewer). For prototype
                    // demo, two lead IDs are hard-mocked as "Reassigned to me"
                    // so the pill is visible without requiring real data.
                    if (_isReassignedToMe(lead.id)) ...[
                      const SizedBox(height: 4),
                      const LeadStatusPill(
                        status: LeadDashStatus.reassignedToMe,
                        dense: true,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Temperature label kept as a small secondary marker —
                    // left RAG bar already conveys colour at a glance.
                    Text(
                      temp.label,
                      style: AppTextStyles.caption.copyWith(
                        color: ragColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    // RM-6: Newly Claimed badge (< 24h since creation)
                    if (DateTime.now().difference(lead.createdAt).inHours < 24) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    if (lead.ibLeadIds.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'IB',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
