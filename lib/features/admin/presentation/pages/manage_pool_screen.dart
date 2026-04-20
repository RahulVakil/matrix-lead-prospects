import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/admin_action_record.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/services/mock/mock_data_generators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/dropped_lead_decision_sheet.dart';

/// Unified Pool Management — combines Assign Leads, Dropped Leads
/// and Request Log into one tabbed interface for Admin/MIS.
class ManagePoolScreen extends StatefulWidget {
  const ManagePoolScreen({super.key});

  @override
  State<ManagePoolScreen> createState() => _ManagePoolScreenState();
}

class _ManagePoolScreenState extends State<ManagePoolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _repo = getIt<LeadRepository>();
  bool _loading = true;
  List<LeadModel> _droppedLeads = [];
  List<LeadModel> _poolLeads = [];
  int _poolCount = 0;
  Map<String, int> _breakdown = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _droppedLeads = await _repo.getDroppedLeads();
    _poolLeads = await _repo.getPoolLeads();
    _poolCount = _poolLeads.length;
    _breakdown = await _repo.getPoolBreakdown();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _assignLead(LeadModel lead, String rmId, String rmName) async {
    await _repo.claimFromPool(lead.id, rmId, rmName);
    if (mounted) {
      showCompassSnack(context, message: '${lead.fullName} assigned to $rmName', type: CompassSnackType.success);
      _load();
    }
  }

  Widget _breakdownPill(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label · $count',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _reviewDropped(LeadModel lead) async {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    await showDroppedLeadDecisionSheet(
      context,
      lead,
      adminId: user.id,
      adminName: user.name,
      onDecision: (record) async {
        if (record.action == AdminLeadAction.returnedToPool) {
          await _repo.returnDroppedToPool(lead.id);
        }
        // Always append audit record. For both decisions the action is durable.
        final refreshed = await _repo.getLeadById(lead.id).catchError((_) => lead);
        await _repo.updateLead(refreshed.copyWith(
          adminActionRecords: [...refreshed.adminActionRecords, record],
        ));
      },
    );
    if (mounted) {
      showCompassSnack(
        context,
        message: 'Decision recorded for ${lead.fullName}',
        type: CompassSnackType.success,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Manage pool',
        subtitle: '$_poolCount in pool · ${_droppedLeads.length} dropped',
      ),
      body: _loading
          ? const Center(child: CompassLoader())
          : Column(
              children: [
                // Pool summary card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyPrimary, AppColors.navyDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_poolCount', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                          const SizedBox(height: 4),
                          Text('In pool', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _breakdownPill('EWG', _breakdown['EWG'] ?? 0),
                          const SizedBox(height: 6),
                          _breakdownPill('PWG', _breakdown['PWG'] ?? 0),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surfacePrimary,
                  child: TabBar(
                    controller: _tabCtrl,
                    labelColor: AppColors.navyPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.navyPrimary,
                    indicatorWeight: 2.5,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(text: 'POOL (${_poolLeads.length})'),
                      const Tab(text: 'REQUESTS'),
                      const Tab(text: 'MAPPED'),
                      Tab(text: 'DROPPED (${_droppedLeads.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _AssignTab(poolLeads: _poolLeads, onAssign: _assignLead),
                      _LeadRequestsTab(),
                      _MappedLeadsTab(onReturnToPool: (lead) async {
                        await _repo.returnDroppedToPool(lead.id);
                        if (mounted) {
                          showCompassSnack(context,
                              message: '${lead.fullName} returned to pool',
                              type: CompassSnackType.success);
                          _load();
                        }
                      }),
                      _DroppedTab(
                        leads: _droppedLeads,
                        onReview: _reviewDropped,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tab 1: Assign leads
// ────────────────────────────────────────────────────────────────────

class _AssignTab extends StatefulWidget {
  final List<LeadModel> poolLeads;
  final void Function(LeadModel lead, String rmId, String rmName) onAssign;

  const _AssignTab({required this.poolLeads, required this.onAssign});

  @override
  State<_AssignTab> createState() => _AssignTabState();
}

class _AssignTabState extends State<_AssignTab> {
  final Set<String> _selected = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == widget.poolLeads.length) {
        _selected.clear();
      } else {
        _selected.addAll(widget.poolLeads.map((l) => l.id));
      }
    });
  }

  void _showAssignSheet() {
    if (_selected.isEmpty) return;
    final rms = MockDataGenerators.allRMs;
    final selectedLeads =
        widget.poolLeads.where((l) => _selected.contains(l.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign ${selectedLeads.length} lead${selectedLeads.length == 1 ? '' : 's'} to RM',
                  style: AppTextStyles.heading3
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height * 0.4),
                  child: ListView(
                    shrinkWrap: true,
                    children: rms
                        .map((rm) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    const Color(0xFFDBEAFE),
                                child: Text(rm.initials,
                                    style: AppTextStyles.caption
                                        .copyWith(
                                            color:
                                                AppColors.navyPrimary,
                                            fontWeight:
                                                FontWeight.w700)),
                              ),
                              title: Text(rm.name,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(
                                          fontWeight:
                                              FontWeight.w600)),
                              subtitle: Text(
                                  rm.designation ?? '',
                                  style: AppTextStyles.caption),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                for (final lead in selectedLeads) {
                                  widget.onAssign(
                                      lead, rm.id, rm.name);
                                }
                                setState(() => _selected.clear());
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.poolLeads.isEmpty) {
      return const CompassEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Pool is empty',
        subtitle: 'No unassigned leads available',
      );
    }
    return Column(
      children: [
        // Selection toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              InkWell(
                onTap: _selectAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selected.length == widget.poolLeads.length
                          ? Icons.check_box
                          : _selected.isEmpty
                              ? Icons.check_box_outline_blank
                              : Icons.indeterminate_check_box,
                      size: 20,
                      color: AppColors.navyPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selected.isEmpty
                          ? 'Select leads'
                          : '${_selected.length} selected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _showAssignSheet,
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: Text('Assign ${_selected.length}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
            itemCount: widget.poolLeads.length,
            itemBuilder: (_, i) {
              final lead = widget.poolLeads[i];
              final isChecked = _selected.contains(lead.id);
              return InkWell(
                onTap: () => _toggleSelection(lead.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppColors.navyPrimary.withValues(alpha: 0.06)
                        : AppColors.surfacePrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChecked
                          ? AppColors.navyPrimary.withValues(alpha: 0.4)
                          : AppColors.borderDefault
                              .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChecked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: isChecked
                            ? AppColors.navyPrimary
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.fullName,
                              style: AppTextStyles.labelLarge
                                  .copyWith(
                                      fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lead.vertical} · ${lead.source.label}',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tab 2: Dropped leads
// ────────────────────────────────────────────────────────────────────

class _DroppedTab extends StatelessWidget {
  final List<LeadModel> leads;
  final ValueChanged<LeadModel> onReview;

  const _DroppedTab({required this.leads, required this.onReview});

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return const CompassEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No dropped leads',
        subtitle: 'All leads are active in the pipeline',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (_, i) {
        final lead = leads[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      PiiDisplay.nameFor(lead.fullName, lead.consentStatus),
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (lead.droppedAt != null)
                    Text(
                      '${lead.droppedAt!.day}/${lead.droppedAt!.month}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.errorRed),
                  const SizedBox(width: 6),
                  Text(
                    lead.dropReason?.label ?? 'Unknown',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'RM: ${lead.assignedRmName}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
              if (lead.dropNotes != null && lead.dropNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  lead.dropNotes!,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              CompassButton(
                label: 'Review decision',
                icon: Icons.gavel_outlined,
                onPressed: () => onReview(lead),
              ),
              if (lead.adminActionRecords.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...lead.adminActionRecords.reversed.take(2).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${r.action == AdminLeadAction.returnedToPool ? "Returned" : "Kept"} by ${r.adminName} · ${r.remarks}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tab 3: Request log
// ────────────────────────────────────────────────────────────────────

class _RequestLogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final requests = List.generate(15, (i) => _LogEntry(
      rmName: MockDataGenerators.allRMs[i % MockDataGenerators.allRMs.length].name,
      vertical: i % 2 == 0 ? 'EWG' : 'PWG',
      count: [3, 2, 5, 1, 4, 3, 2, 5, 1, 4, 2, 3, 1, 4, 2][i],
      status: i < 5 ? 'Pending' : i < 10 ? 'Approved' : 'Denied',
      requestedAgo: '${i + 1}h ago',
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final r = requests[i];
        final statusColor = r.status == 'Approved'
            ? AppColors.successGreen
            : r.status == 'Denied'
                ? AppColors.errorRed
                : AppColors.warmAmber;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.rmName,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${r.count} leads · ${r.vertical} · ${r.requestedAgo}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogEntry {
  final String rmName;
  final String vertical;
  final int count;
  final String status;
  final String requestedAgo;
  const _LogEntry({
    required this.rmName,
    required this.vertical,
    required this.count,
    required this.status,
    required this.requestedAgo,
  });
}

// ────────────────────────────────────────────────────────────────────
// Tab: Lead Requests (Admin-3)
// ────────────────────────────────────────────────────────────────────

class _LeadRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock: 3 RMs with outstanding requests.
    final requests = [
      _RequestRow('Priya Sharma', 'RM', 2, 12),
      _RequestRow('Karan Kapoor', 'RM', 5, 8),
      _RequestRow('Neha Kulkarni', 'RM', 3, 6),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Outstanding lead requests',
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...requests.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.borderDefault.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.avatarBackground,
                        child: Text(
                          r.name.split(' ').map((w) => w[0]).take(2).join(),
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r.name,
                            style: AppTextStyles.labelLarge
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${r.requested} leads requested · ${r.currentAllocation} currently allocated',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _RequestRow {
  final String name;
  final String role;
  final int requested;
  final int currentAllocation;
  const _RequestRow(this.name, this.role, this.requested, this.currentAllocation);
}

// ────────────────────────────────────────────────────────────────────
// Tab: Mapped Leads (Admin-4)
// ────────────────────────────────────────────────────────────────────

class _MappedLeadsTab extends StatelessWidget {
  final ValueChanged<LeadModel> onReturnToPool;
  const _MappedLeadsTab({required this.onReturnToPool});

  @override
  Widget build(BuildContext context) {
    // Mock: 20 allocated leads across RMs. Uses the leads repository.
    return FutureBuilder<List<LeadModel>>(
      future: getIt<LeadRepository>().getLeads(page: 1, pageSize: 20).then((r) =>
          r.items.where((l) => l.stage != LeadStage.dropped).take(20).toList()),
      builder: (context, snap) {
        if (!snap.hasData) return const CompassLoader();
        final leads = snap.data!;
        if (leads.isEmpty) {
          return const CompassEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No mapped leads',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leads.length,
          itemBuilder: (_, i) {
            final l = leads[i];
            final daysSince =
                DateTime.now().difference(l.createdAt).inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.borderDefault.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.fullName,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    'RM: ${l.assignedRmName} · ${l.stage.label} · $daysSince days ago',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
