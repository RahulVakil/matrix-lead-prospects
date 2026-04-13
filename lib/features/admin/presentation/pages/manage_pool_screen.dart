import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/services/mock/mock_data_generators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

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
    _tabCtrl = TabController(length: 3, vsync: this);
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

  Future<void> _returnToPool(LeadModel lead) async {
    await _repo.returnDroppedToPool(lead.id);
    if (mounted) {
      showCompassSnack(context, message: '${lead.fullName} returned to pool', type: CompassSnackType.success);
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
                      Tab(text: 'ASSIGN (${MockDataGenerators.allRMs.length})'),
                      Tab(text: 'DROPPED (${_droppedLeads.length})'),
                      const Tab(text: 'LOG'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _AssignTab(poolLeads: _poolLeads, onAssign: _assignLead),
                      _DroppedTab(
                        leads: _droppedLeads,
                        onReturn: _returnToPool,
                      ),
                      _RequestLogTab(),
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

class _AssignTab extends StatelessWidget {
  final List<LeadModel> poolLeads;
  final void Function(LeadModel lead, String rmId, String rmName) onAssign;

  const _AssignTab({required this.poolLeads, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    if (poolLeads.isEmpty) {
      return const CompassEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Pool is empty',
        subtitle: 'No unassigned leads available',
      );
    }
    final rms = MockDataGenerators.allRMs;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: poolLeads.length,
      itemBuilder: (_, i) {
        final lead = poolLeads[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.fullName,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    lead.source.label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${lead.vertical} · ${lead.aumDisplay}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assign to RM', style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 14),
                                ...rms.map((rm) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFDBEAFE),
                                        child: Text(rm.initials, style: AppTextStyles.caption.copyWith(color: AppColors.navyPrimary, fontWeight: FontWeight.w700)),
                                      ),
                                      title: Text(rm.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                      subtitle: Text(rm.designation ?? '', style: AppTextStyles.caption),
                                      onTap: () {
                                        Navigator.pop(context);
                                        onAssign(lead, rm.id, rm.name);
                                      },
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Assign to...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Tab 2: Dropped leads
// ────────────────────────────────────────────────────────────────────

class _DroppedTab extends StatelessWidget {
  final List<LeadModel> leads;
  final ValueChanged<LeadModel> onReturn;

  const _DroppedTab({required this.leads, required this.onReturn});

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
                      lead.fullName,
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
                label: 'Return to pool',
                icon: Icons.replay,
                onPressed: () => onReturn(lead),
              ),
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
