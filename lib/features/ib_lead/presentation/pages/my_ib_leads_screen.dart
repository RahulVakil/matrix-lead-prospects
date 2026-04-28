import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../core/widgets/ib_progress_status_pill.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../routing/route_names.dart';

/// Role-aware IB Leads list. Title, scope, statuses shown, and edit-permission
/// vary by role:
///   RM       — own IB leads (created by this RM)
///   Team Lead — team's IB leads (view-only unless TL created)
///   Admin/MIS — every IB lead, with Pending review prioritised at top
///   IB user  — only Approved IB leads (their work bucket)
class MyIbLeadsScreen extends StatefulWidget {
  const MyIbLeadsScreen({super.key});

  @override
  State<MyIbLeadsScreen> createState() => _MyIbLeadsScreenState();
}

class _MyIbLeadsScreenState extends State<MyIbLeadsScreen> {
  final IbLeadRepository _ibRepo = getIt<IbLeadRepository>();
  final LeadRepository _leadRepo = getIt<LeadRepository>();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<IbLeadModel> _leads = [];
  IbLeadStatus? _statusFilter;
  // Progress status filter — multi-select. The "Awaiting first update"
  // pseudo-status (approved lead with no progress entries yet) is tracked
  // separately so it composes with the 6 enum values.
  final Set<IbProgressStatus> _progressFilter = {};
  bool _progressAwaitingFilter = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;

    List<IbLeadModel> merged = [];
    switch (user.role) {
      case UserRole.rm:
        merged = await _loadForRm(user.id);
        break;
      case UserRole.teamLead:
        merged = await _loadForTeamLead(user.id);
        break;
      case UserRole.admin:
        merged = await _ibRepo.getAllForBranchHead(user.id);
        break;
      case UserRole.ib:
        final all = await _ibRepo.getAllForBranchHead(user.id);
        merged = all.where((l) => l.status.isApproved).toList();
        break;
      default:
        merged = await _ibRepo.getMyLeads(user.id);
    }

    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _leads = merged;
      _loading = false;
    });
  }

  Future<List<IbLeadModel>> _loadForRm(String rmId) async {
    final byMe = await _ibRepo.getMyLeads(rmId);
    final ids = <String>{for (final l in byMe) l.id};
    final out = <IbLeadModel>[...byMe];
    try {
      final leadResult =
          await _leadRepo.getLeads(page: 1, pageSize: 500, assignedRmId: rmId);
      for (final lead in leadResult.items) {
        for (final ibId in lead.ibLeadIds) {
          if (ids.contains(ibId)) continue;
          final found = await _ibRepo.getById(ibId);
          if (found != null) {
            ids.add(ibId);
            out.add(found);
          }
        }
      }
    } catch (_) {}
    return out;
  }

  Future<List<IbLeadModel>> _loadForTeamLead(String tlId) async {
    // Mock-friendly: include this TL's own IB leads + every IB lead in the
    // pool. In production this would filter by TL's team membership.
    final mine = await _ibRepo.getMyLeads(tlId);
    final all = await _ibRepo.getAllForBranchHead(tlId);
    final byId = <String, IbLeadModel>{};
    for (final l in all) {
      byId[l.id] = l;
    }
    for (final l in mine) {
      byId[l.id] = l;
    }
    return byId.values.toList();
  }

  List<IbLeadModel> get _filtered {
    var list = _leads;
    // Status filter
    if (_statusFilter != null) {
      list = list.where((l) {
        if (_statusFilter == IbLeadStatus.approved) return l.status.isApproved;
        if (_statusFilter == IbLeadStatus.pending) return l.status.isAwaitingReview;
        return l.status == _statusFilter;
      }).toList();
    }
    // Progress status filter — composes with status filter.
    if (_progressFilter.isNotEmpty || _progressAwaitingFilter) {
      list = list.where((l) {
        final ls = l.latestProgressStatus;
        final isAwaiting = ls == null && l.status.isApproved;
        return (ls != null && _progressFilter.contains(ls)) ||
            (_progressAwaitingFilter && isAwaiting);
      }).toList();
    }
    // Search filter (#6)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) =>
          l.companyName.toLowerCase().contains(q) ||
          (l.clientName?.toLowerCase().contains(q) ?? false) ||
          l.dealType.label.toLowerCase().contains(q) ||
          l.createdByName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    final role = user?.role ?? UserRole.rm;
    final title = switch (role) {
      UserRole.admin => 'IB Leads — Admin / MIS',
      UserRole.ib => 'IB Leads',
      UserRole.teamLead => 'My IB Leads (Team)',
      _ => 'My IB Leads',
    };
    final subtitle = '${_filtered.length} of ${_leads.length}';
    final sentBack =
        _leads.where((l) => l.status == IbLeadStatus.sentBack).toList();

    return HeroScaffold(
      header: HeroAppBar.simple(title: title, subtitle: subtitle),
      body: _loading
          ? const Center(child: CompassLoader())
          : RefreshIndicator(
              color: AppColors.navyPrimary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                children: [
                  // Search bar (#6)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by company, client, deal type…',
                        hintStyle: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                splashRadius: 18,
                              ),
                        filled: true,
                        fillColor: AppColors.surfaceTertiary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.navyPrimary, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  if (role == UserRole.rm && sentBack.isNotEmpty) ...[
                    _SentBackStrip(leads: sentBack),
                    const SizedBox(height: 14),
                  ],
                  if (role != UserRole.ib) ...[
                    const _FilterGroupLabel('Approval status'),
                    const SizedBox(height: 6),
                    _StatusFilterBar(
                      value: _statusFilter,
                      onChanged: (s) => setState(() => _statusFilter = s),
                      counts: _statusCounts(),
                      role: role,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const _FilterGroupLabel('Progress status (30-day cycle)'),
                  const SizedBox(height: 6),
                  _ProgressFilterBar(
                    selected: _progressFilter,
                    awaitingSelected: _progressAwaitingFilter,
                    onToggle: (s) => setState(() {
                      _progressFilter.contains(s)
                          ? _progressFilter.remove(s)
                          : _progressFilter.add(s);
                    }),
                    onToggleAwaiting: () => setState(() =>
                        _progressAwaitingFilter = !_progressAwaitingFilter),
                  ),
                  const SizedBox(height: 12),
                  if (_filtered.isEmpty)
                    CompassEmptyState(
                      icon: Icons.account_tree_outlined,
                      title: role == UserRole.ib
                          ? 'No approved IB leads yet'
                          : 'No IB leads here',
                    )
                  else
                    ..._filtered.map(
                        (ib) => _IbLeadCard(lead: ib, viewerRole: role)),
                ],
              ),
            ),
    );
  }

  Map<IbLeadStatus, int> _statusCounts() {
    final map = <IbLeadStatus, int>{};
    for (final l in _leads) {
      // Collapse to user-facing buckets: forwarded => approved, draft => pending.
      var key = l.status;
      if (key == IbLeadStatus.forwarded) key = IbLeadStatus.approved;
      if (key == IbLeadStatus.draft) key = IbLeadStatus.pending;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────
// IB Lead card (shared across roles)
// ─────────────────────────────────────────────────────────────────────

class _IbLeadCard extends StatelessWidget {
  final IbLeadModel lead;
  final UserRole viewerRole;

  const _IbLeadCard({required this.lead, required this.viewerRole});

  bool get _maskIdentity {
    if (!lead.isConfidential) return false;
    // Creator + TL always see full. Admin / IB see masked unless assigned.
    if (viewerRole == UserRole.teamLead) return false;
    return lead.assignedIbRmId == null &&
        (viewerRole == UserRole.admin || viewerRole == UserRole.ib);
  }

  String get _displayCompany =>
      _maskIdentity ? 'Confidential lead · #${lead.id}' : lead.companyName;

  Color _statusColor(IbLeadStatus s) {
    if (s.isApproved) return AppColors.successGreen;
    return switch (s) {
      // draft + pending share the "Lead Created" label and color (both are
      // routed to Admin/MIS review automatically).
      IbLeadStatus.draft => AppColors.warmAmber,
      IbLeadStatus.pending => AppColors.warmAmber,
      IbLeadStatus.sentBack => AppColors.errorRed,
      IbLeadStatus.dropped => AppColors.dormantGray,
      _ => AppColors.textHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(lead.status);
    final isSentBack = lead.status == IbLeadStatus.sentBack;
    // #12 — tint the card by status color so the status is readable at a glance.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(RouteNames.ibLeadDetailPath(lead.id)),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // #7: Left bar colored by status (no temperature tagging)
                    Container(
                      width: 3,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor,
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
                              if (lead.isConfidential) ...[
                                const Icon(Icons.lock,
                                    size: 14, color: AppColors.errorRed),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                child: Text(
                                  _displayCompany,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: lead.isConfidential
                                        ? AppColors.errorRed
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lead.dealValue != null
                                ? IndianCurrencyFormatter.shortForm(
                                    lead.dealValue!)
                                : lead.dealValueRange.label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.navyPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lead.dealType.label} · ${lead.timelineDisplay} · RM ${lead.createdByName}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lead.status.label,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        // 30-day progress status pill: shown for any approved
                        // lead, with an "Awaiting update" variant when no
                        // progress entry exists yet.
                        if (lead.status.isApproved) ...[
                          const SizedBox(height: 4),
                          IbProgressStatusPill(
                              status: lead.latestProgressStatus),
                        ],
                        // Overdue / Escalated flags
                        if (lead.isProgressEscalated) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '${lead.daysSinceLastProgress}d',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ] else if (lead.isProgressOverdue) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warmAmber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '${lead.daysSinceLastProgress}d',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (isSentBack && (lead.remarks ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.report_gmailerrorred,
                            size: 16, color: AppColors.errorRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textPrimary),
                              children: [
                                const TextSpan(
                                  text: 'Reason: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                                TextSpan(text: lead.remarks!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────
// Sent-back strip (RM only)
// ─────────────────────────────────────────────────────────────────────

class _SentBackStrip extends StatelessWidget {
  final List<IbLeadModel> leads;
  const _SentBackStrip({required this.leads});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.replay_circle_filled,
              color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${leads.length} sent back — needs your action',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.push(RouteNames.ibLeadDetailPath(leads.first.id)),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Status filter bar
// ─────────────────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final IbLeadStatus? value;
  final ValueChanged<IbLeadStatus?> onChanged;
  final Map<IbLeadStatus, int> counts;
  final UserRole role;
  const _StatusFilterBar({
    required this.value,
    required this.onChanged,
    required this.counts,
    required this.role,
  });

  /// User-facing statuses (per spec): Lead Created (uses pending bucket),
  /// Sent Back, Approved, Dropped / Closed. We hide draft + forwarded since
  /// they collapse into pending and approved respectively.
  List<IbLeadStatus> _statusesForRole() {
    return [
      IbLeadStatus.pending, // labelled "Lead Created"
      IbLeadStatus.sentBack,
      IbLeadStatus.approved,
      IbLeadStatus.dropped,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('All', value == null, () => onChanged(null)),
          const SizedBox(width: 6),
          for (final s in _statusesForRole()) ...[
            _chip(
              counts[s] == null ? s.label : '${s.label}  ${counts[s]}',
              value == s,
              () => onChanged(s),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyPrimary.withValues(alpha: 0.12)
              : AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.navyPrimary.withValues(alpha: 0.4)
                : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.navyPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Filter group label (muted caption shown above each chip row)
// ─────────────────────────────────────────────────────────────────────

class _FilterGroupLabel extends StatelessWidget {
  final String text;
  const _FilterGroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Progress status filter bar (multi-select)
// ─────────────────────────────────────────────────────────────────────

class _ProgressFilterBar extends StatelessWidget {
  final Set<IbProgressStatus> selected;
  final bool awaitingSelected;
  final ValueChanged<IbProgressStatus> onToggle;
  final VoidCallback onToggleAwaiting;
  const _ProgressFilterBar({
    required this.selected,
    required this.awaitingSelected,
    required this.onToggle,
    required this.onToggleAwaiting,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in IbProgressStatus.values) ...[
            _chip(s.label, selected.contains(s), () => onToggle(s)),
            const SizedBox(width: 6),
          ],
          _chip('Awaiting first update', awaitingSelected, onToggleAwaiting),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.navyPrimary.withValues(alpha: 0.12)
              : AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.navyPrimary.withValues(alpha: 0.4)
                : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.navyPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
