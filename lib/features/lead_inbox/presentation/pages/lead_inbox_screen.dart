import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/create_chooser_sheet.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/lead_inbox_cubit.dart';

// ── RAG color mapping (stage → temperature color) ────────────────────
// Lead / Dropped = Cold = Blue
// Profiling / Engage = Warm = Amber
// Onboarded = Hot = Red
Color _stageRagColor(LeadStage stage) {
  switch (stage) {
    case LeadStage.lead:
    case LeadStage.dropped:
      return AppColors.coldBlue;
    case LeadStage.profiling:
    case LeadStage.engage:
      return AppColors.warmAmber;
    case LeadStage.onboard:
      return AppColors.hotRed;
    default:
      return AppColors.dormantGray;
  }
}

/// All Leads listing — mobile-first, clean filter sheet, RAG stage color.
class LeadInboxScreen extends StatelessWidget {
  const LeadInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => LeadInboxCubit(rmId: user.id)..loadLeads(refresh: true),
      child: const _InboxBody(),
    );
  }
}

class _InboxBody extends StatefulWidget {
  const _InboxBody();

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
            (state.stageFilter != null ? 1 : 0) +
            (state.ibLinkedOnly ? 1 : 0) +
            (state.myLeadsOnly ? 1 : 0);

        return HeroScaffold(
          header: HeroAppBar.simple(
              title: 'All leads', subtitle: '${state.totalCount} total'),
          // #8 — FAB uses shared chooser with IB-block (#9)
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.navyPrimary,
            onPressed: () => showCreateChooser(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              // ── Search (#1, #2) ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: CompassTextField(
                  controller: _searchCtrl,
                  hint: 'Search by name, company, group, or code…',
                  prefixIcon: Icons.search,
                  onChanged: cubit.search,
                  suffix: (state.searchQuery ?? '').isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            cubit.search('');
                          },
                          splashRadius: 18,
                          tooltip: 'Clear search',
                        ),
                ),
              ),

              // ── Filter pill + Sort dropdown (#3, #4) ───────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Row(
                  children: [
                    // Filter pill → opens bottom sheet
                    InkWell(
                      onTap: () => _showFilterSheet(context, state, cubit),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: activeFilterCount > 0
                              ? AppColors.navyPrimary.withValues(alpha: 0.1)
                              : AppColors.surfaceTertiary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: activeFilterCount > 0
                                ? AppColors.navyPrimary.withValues(alpha: 0.4)
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune,
                                size: 15,
                                color: activeFilterCount > 0
                                    ? AppColors.navyPrimary
                                    : AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              activeFilterCount > 0
                                  ? 'Filter  $activeFilterCount'
                                  : 'Filter',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: activeFilterCount > 0
                                    ? AppColors.navyPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Sort dropdown — 4 options only (#4)
                    DropdownButton<String>(
                      value: state.sortBy ?? 'name',
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.navyPrimary),
                      items: const [
                        DropdownMenuItem(
                            value: 'name', child: Text('Name A – Z')),
                        DropdownMenuItem(
                            value: 'aum', child: Text('AUM (high → low)')),
                        DropdownMenuItem(
                            value: 'created_desc',
                            child: Text('Created (latest)')),
                        DropdownMenuItem(
                            value: 'created_asc',
                            child: Text('Created (oldest)')),
                      ],
                      onChanged: (v) {
                        if (v != null) cubit.setSort(v);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── List ────────────────────────────────────────────
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.navyPrimary))
                    : state.leads.isEmpty
                        ? Center(
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
                                    _searchCtrl.clear();
                                    cubit.setStageFilter(null);
                                    cubit.setIbLinkedOnly(false);
                                    cubit.search('');
                                  },
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.navyPrimary,
                            onRefresh: () => cubit.loadLeads(refresh: true),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 10, 14, 96),
                              itemCount: state.leads.length,
                              itemBuilder: (_, i) {
                                final lead = state.leads[i];
                                final showDate =
                                    state.sortBy == 'created_desc' ||
                                    state.sortBy == 'created_asc';
                                final user = context
                                    .read<AuthCubit>()
                                    .state
                                    .currentUser;
                                final isTl =
                                    user?.role == UserRole.teamLead;
                                return _LeadCard(
                                  lead: lead,
                                  showCreatedDate: showDate,
                                  isMyLead: isTl &&
                                      lead.assignedRmId == user?.id,
                                  highlightQuery: state.searchQuery,
                                  onTap: () => context.push(
                                    RouteNames.leadDetailPath(lead.id),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
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
        initialStage: state.stageFilter,
        initialIbOnly: state.ibLinkedOnly,
        initialMyOnly: state.myLeadsOnly,
        showMyLeadsToggle: context.read<AuthCubit>().state.currentUser?.role == UserRole.teamLead,
        onApply: (stage, ibOnly, myOnly) {
          cubit.setStageFilter(stage);
          cubit.setIbLinkedOnly(ibOnly);
          cubit.setMyLeadsOnly(myOnly);
        },
      ),
    );
  }
}

class _FilterSheetBody extends StatefulWidget {
  final LeadStage? initialStage;
  final bool initialIbOnly;
  final bool initialMyOnly;
  final bool showMyLeadsToggle;
  final void Function(LeadStage? stage, bool ibOnly, bool myOnly) onApply;

  const _FilterSheetBody({
    required this.initialStage,
    required this.initialIbOnly,
    required this.initialMyOnly,
    required this.showMyLeadsToggle,
    required this.onApply,
  });

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late LeadStage? _stageF;
  late bool _ibOnly;
  late bool _myOnly;

  @override
  void initState() {
    super.initState();
    _stageF = widget.initialStage;
    _ibOnly = widget.initialIbOnly;
    _myOnly = widget.initialMyOnly;
  }

  static final _stages = [
    ...LeadStage.activePipeline,
    LeadStage.dropped,
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
                    _stageF = null;
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
                CompassChoiceChip<LeadStage?>(
                  value: null,
                  groupValue: _stageF,
                  label: 'All',
                  onSelected: (_) => setState(() => _stageF = null),
                ),
                ..._stages.map((s) => CompassChoiceChip<LeadStage?>(
                      value: s,
                      groupValue: _stageF,
                      label: s.label,
                      color: _stageRagColor(s),
                      onSelected: (v) => setState(() => _stageF = v),
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
                  widget.onApply(_stageF, _ibOnly, _myOnly);
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
// Lead card (#10) — Name + Source + Stage pill with RAG color
// ─────────────────────────────────────────────────────────────────────

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
    final ragColor = _stageRagColor(lead.stage);
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status pill + badges (right-aligned column)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ragColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lead.stage.label,
                        style: AppTextStyles.caption.copyWith(
                          color: ragColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
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
