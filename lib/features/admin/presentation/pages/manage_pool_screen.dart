import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/admin_action_record.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/reassignment_request.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/repositories/reassignment_repository.dart';
import '../../../../core/services/mock/mock_data_generators.dart';
import '../../../../core/services/mock_notification_queue.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

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
  final _reassignRepo = getIt<ReassignmentRepository>();
  bool _loading = true;
  List<LeadModel> _droppedLeads = [];
  List<LeadModel> _poolLeads = [];
  List<ReassignmentRequest> _reassignments = [];
  int _poolCount = 0;
  Map<String, int> _breakdown = {};

  @override
  void initState() {
    super.initState();
    // 5 tabs: Pool, Requests, Reassignment, Mapped, Dropped.
    _tabCtrl = TabController(length: 5, vsync: this);
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
    _reassignments = await _reassignRepo.getAllPending();
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

  /// Approve a pending reassignment request. Notifies both source RM
  /// (capturing) and target RM (current owner) via the in-app + email queue.
  Future<void> _approveReassignment(ReassignmentRequest req) async {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve reassignment?'),
        content: Text(
          '${req.matchedClientName} will be reassigned to ${req.sourceRmName}. '
          '${req.targetRmName != null ? "${req.targetRmName} will be notified." : ""}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _reassignRepo.approve(req.id, adminId: user.id, adminName: user.name);

    // Source RM notification — they may now capture the lead.
    MockNotificationQueue.pushInApp(
      recipientId: req.sourceRmId,
      recipientName: req.sourceRmName,
      title: 'Reassignment approved',
      body:
          'You may now capture ${req.matchedClientName}. Approved by ${user.name}.',
    );
    MockNotificationQueue.pushEmail(
      to: '${req.sourceRmName.toLowerCase().replaceAll(' ', '.')}@jmfs.in',
      subject: 'Reassignment approved — ${req.matchedClientName}',
      body:
          'Your reassignment request for ${req.matchedClientName} has been approved by ${user.name}. You may now capture this lead in JM Matrix.',
    );
    // Target RM notification — only if known.
    if (req.targetRmId != null && req.targetRmName != null) {
      MockNotificationQueue.pushInApp(
        recipientId: req.targetRmId!,
        recipientName: req.targetRmName!,
        title: 'Client reassigned',
        body:
            '${req.matchedClientName} has been reassigned from your portfolio to ${req.sourceRmName}.',
      );
      MockNotificationQueue.pushEmail(
        to: '${req.targetRmName!.toLowerCase().replaceAll(' ', '.')}@jmfs.in',
        subject: 'Client reassigned — ${req.matchedClientName}',
        body:
            '${req.matchedClientName} has been reassigned from your portfolio to ${req.sourceRmName}. Approved by ${user.name}.',
      );
    }
    if (mounted) {
      showCompassSnack(context,
          message: 'Reassignment approved · both RMs notified',
          type: CompassSnackType.success);
      _load();
    }
  }

  /// Reject with a mandatory reason. Notifies source RM only.
  Future<void> _rejectReassignment(ReassignmentRequest req) async {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    final reason = await _promptForReason(context);
    if (reason == null || !mounted) return;
    await _reassignRepo.reject(req.id,
        reason: reason, adminId: user.id, adminName: user.name);
    MockNotificationQueue.pushInApp(
      recipientId: req.sourceRmId,
      recipientName: req.sourceRmName,
      title: 'Reassignment rejected',
      body:
          'Your reassignment request for ${req.matchedClientName} was rejected. Reason: $reason',
    );
    MockNotificationQueue.pushEmail(
      to: '${req.sourceRmName.toLowerCase().replaceAll(' ', '.')}@jmfs.in',
      subject: 'Reassignment rejected — ${req.matchedClientName}',
      body:
          'Your reassignment request was rejected by ${user.name}. Reason: $reason',
    );
    if (mounted) {
      showCompassSnack(context,
          message: 'Reassignment rejected · ${req.sourceRmName} notified',
          type: CompassSnackType.warn);
      _load();
    }
  }

  /// Bulk-assign N pool leads to a single RM. Used by both the multi-select
  /// picker and the CSV bulk upload flows.
  Future<void> _bulkAssign(
      List<String> leadIds, String rmId, String rmName) async {
    var ok = 0;
    var fail = 0;
    for (final id in leadIds) {
      try {
        await _repo.claimFromPool(id, rmId, rmName);
        ok++;
      } catch (_) {
        fail++;
      }
    }
    if (mounted) {
      showCompassSnack(context,
          message: fail == 0
              ? '$ok leads assigned to $rmName'
              : '$ok assigned · $fail failed',
          type: fail == 0
              ? CompassSnackType.success
              : CompassSnackType.warn);
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
                      Tab(text: 'REASSIGN (${_reassignments.length})'),
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
                      _LeadRequestsTab(
                        poolLeads: _poolLeads,
                        onBulkAssign: _bulkAssign,
                      ),
                      _ReassignmentTab(
                        requests: _reassignments,
                        onApprove: _approveReassignment,
                        onReject: _rejectReassignment,
                      ),
                      _MappedLeadsTab(onReturnToPool: (lead) async {
                        await _repo.returnDroppedToPool(lead.id);
                        if (mounted) {
                          showCompassSnack(context,
                              message: '${lead.fullName} returned to pool',
                              type: CompassSnackType.success);
                          _load();
                        }
                      }),
                      _DroppedTab(leads: _droppedLeads),
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

  const _DroppedTab({required this.leads});

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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Review workflow retired — Dropped tab now displays only.
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
// Tab: Lead Requests — Admin clicks an RM to open a multi-select pool
// leads picker (with optional CSV bulk upload) for batch assignment.
// ────────────────────────────────────────────────────────────────────

class _LeadRequestsTab extends StatelessWidget {
  final List<LeadModel> poolLeads;
  /// Called with (leadIds, rmId, rmName) once the admin confirms.
  final Future<void> Function(List<String>, String, String) onBulkAssign;

  const _LeadRequestsTab({
    required this.poolLeads,
    required this.onBulkAssign,
  });

  @override
  Widget build(BuildContext context) {
    // Demo: 3 RMs with outstanding pool requests. In production this
    // would come from a `RequestsRepository`.
    final rms = MockDataGenerators.allRMs;
    final requests = [
      _RequestRow(rms[0], 2),
      _RequestRow(rms[3], 5),
      _RequestRow(rms[7], 3),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Outstanding lead requests · tap a name to assign',
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...requests.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openPicker(context, r),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
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
                                r.rm.name
                                    .split(' ')
                                    .map((w) => w.isEmpty ? '' : w[0])
                                    .take(2)
                                    .join(),
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.navyDark,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.rm.name,
                                      style: AppTextStyles.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                    '${r.rm.teamName ?? "—"} · ${r.rm.vertical ?? "—"}',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.textHint),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${r.requested} leads requested',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context, _RequestRow r) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestsLeadsPickerSheet(
        rmName: r.rm.name,
        rmVertical: r.rm.vertical,
        poolLeads: poolLeads,
        onConfirm: (leadIds) async {
          await onBulkAssign(leadIds, r.rm.id, r.rm.name);
        },
      ),
    );
  }
}

class _RequestRow {
  final dynamic rm; // UserModel — kept dynamic to avoid an extra import here.
  final int requested;
  const _RequestRow(this.rm, this.requested);
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

// ────────────────────────────────────────────────────────────────────
// Tab: Reassignment Requests
// ────────────────────────────────────────────────────────────────────

class _ReassignmentTab extends StatelessWidget {
  final List<ReassignmentRequest> requests;
  final Future<void> Function(ReassignmentRequest) onApprove;
  final Future<void> Function(ReassignmentRequest) onReject;

  const _ReassignmentTab({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const CompassEmptyState(
        icon: Icons.swap_horizontal_circle_outlined,
        title: 'No pending reassignment requests',
        subtitle:
            'When an RM hits Coverage and requests reassignment, it lands here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final r = requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.matchedClientName,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${r.createdAt.day}/${r.createdAt.month}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.swap_horiz,
                      size: 14, color: AppColors.warmAmber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'From: ${r.targetRmName ?? "—"}  →  To: ${r.sourceRmName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(r.reason, style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CompassButton.secondary(
                      label: 'Reject',
                      icon: Icons.close,
                      onPressed: () => onReject(r),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CompassButton(
                      label: 'Approve',
                      icon: Icons.check,
                      onPressed: () => onApprove(r),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reassignment-rejection reason prompt.
Future<String?> _promptForReason(BuildContext context) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reject reassignment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'A reason is required so the requesting RM understands the decision.'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            minLines: 2,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final v = ctrl.text.trim();
            if (v.isEmpty) return;
            Navigator.pop(ctx, v);
          },
          child: const Text('Reject'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

// ────────────────────────────────────────────────────────────────────
// Requests-tab leads picker — multi-select pool leads + CSV bulk upload
// (paste-CSV mode for demo without filesystem deps).
// ────────────────────────────────────────────────────────────────────

class _RequestsLeadsPickerSheet extends StatefulWidget {
  final String rmName;
  final String? rmVertical;
  final List<LeadModel> poolLeads;
  final Future<void> Function(List<String> leadIds) onConfirm;

  const _RequestsLeadsPickerSheet({
    required this.rmName,
    required this.rmVertical,
    required this.poolLeads,
    required this.onConfirm,
  });

  @override
  State<_RequestsLeadsPickerSheet> createState() =>
      _RequestsLeadsPickerSheetState();
}

class _RequestsLeadsPickerSheetState
    extends State<_RequestsLeadsPickerSheet> {
  final Set<String> _selected = {};
  bool _filterByRmVertical = true;

  List<LeadModel> get _visible =>
      _filterByRmVertical && widget.rmVertical != null
          ? widget.poolLeads
              .where((l) => l.vertical == widget.rmVertical)
              .toList()
          : widget.poolLeads;

  Future<void> _confirm() async {
    if (_selected.isEmpty) return;
    Navigator.pop(context);
    await widget.onConfirm(_selected.toList());
  }

  Future<void> _bulkUpload() async {
    final ids = await _showCsvPasteDialog(context, widget.poolLeads);
    if (ids == null || ids.isEmpty || !mounted) return;
    Navigator.pop(context);
    await widget.onConfirm(ids);
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == _visible.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_visible.map((l) => l.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Column(
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
                    const SizedBox(height: 12),
                    Text('Assign to ${widget.rmName}',
                        style: AppTextStyles.heading3
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      widget.rmVertical != null
                          ? 'Vertical: ${widget.rmVertical}  ·  ${_visible.length} pool leads'
                          : '${_visible.length} pool leads',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (widget.rmVertical != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: _filterByRmVertical,
                            onChanged: (v) =>
                                setState(() => _filterByRmVertical = v),
                            activeColor: AppColors.navyPrimary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Show only ${widget.rmVertical} pool leads',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _toggleAll,
                          icon: Icon(
                            _selected.length == _visible.length &&
                                    _visible.isNotEmpty
                                ? Icons.indeterminate_check_box
                                : Icons.select_all,
                            size: 18,
                          ),
                          label: Text(
                            _selected.length == _visible.length &&
                                    _visible.isNotEmpty
                                ? 'Clear'
                                : 'Select all',
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _bulkUpload,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Bulk upload CSV'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _visible.isEmpty
                    ? const CompassEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Pool is empty',
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: _visible.length,
                        itemBuilder: (_, i) {
                          final l = _visible[i];
                          final picked = _selected.contains(l.id);
                          return CheckboxListTile(
                            value: picked,
                            dense: true,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            activeColor: AppColors.navyPrimary,
                            onChanged: (_) => _toggle(l.id),
                            title: Text(l.fullName,
                                style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            subtitle: Text(
                              '${l.id} · ${l.vertical} · ${l.source.label}'
                              '${(l.companyName ?? "").isNotEmpty ? " · ${l.companyName}" : ""}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: CompassButton(
                    label: _selected.isEmpty
                        ? 'Select leads to assign'
                        : 'Assign ${_selected.length} ${_selected.length == 1 ? "lead" : "leads"}',
                    icon: Icons.send,
                    onPressed: _selected.isEmpty ? null : _confirm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSV paste dialog. Format = Lead ID, Full Name, Phone, Email, Vertical,
/// Source, Company, City. Only Lead ID is used; the rest are verification
/// columns. Includes a "Copy Template" action that builds a CSV from the
/// current pool so the admin can edit and re-paste.
Future<List<String>?> _showCsvPasteDialog(
    BuildContext context, List<LeadModel> pool) async {
  final ctrl = TextEditingController();
  final template = StringBuffer()
    ..writeln('Lead ID,Full Name,Phone,Email,Vertical,Source,Company,City');
  for (final l in pool) {
    template.writeln([
      l.id,
      _csvField(l.fullName),
      _csvField(l.phone ?? ''),
      _csvField(l.email ?? ''),
      l.vertical,
      _csvField(l.source.label),
      _csvField(l.companyName ?? ''),
      _csvField(l.city ?? ''),
    ].join(','));
  }

  final result = await showDialog<List<String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bulk upload — paste CSV'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Format: Lead ID, Full Name, Phone, Email, Vertical, Source, Company, City'),
            const SizedBox(height: 4),
            const Text(
              'Only Lead ID is used for assignment; other columns are verification only.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: template.toString()));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Template copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Copy template'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              maxLines: 8,
              minLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                hintText: 'Paste CSV here (with or without header row)…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final ids = _parseCsvLeadIds(ctrl.text);
            Navigator.pop(ctx, ids);
          },
          child: const Text('Import'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

String _csvField(String v) {
  if (v.contains(',') || v.contains('"')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

List<String> _parseCsvLeadIds(String csv) {
  final out = <String>[];
  for (final raw in csv.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.toLowerCase().startsWith('lead id')) continue;
    var firstComma = line.indexOf(',');
    if (firstComma == -1) firstComma = line.length;
    var id = line.substring(0, firstComma).trim();
    if (id.startsWith('"') && id.endsWith('"') && id.length >= 2) {
      id = id.substring(1, id.length - 1);
    }
    if (id.isNotEmpty) out.add(id);
  }
  return out;
}
