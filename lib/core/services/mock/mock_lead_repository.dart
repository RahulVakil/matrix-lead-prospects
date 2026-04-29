import '../../enums/lead_entity_type.dart';
import '../../enums/lead_stage.dart';
import '../../enums/lead_temperature.dart';
import '../../enums/lead_source.dart';
import '../../enums/loss_reason.dart';
import '../../enums/update_type.dart';
import '../../models/client_master_record.dart';
import '../../models/lead_model.dart';
import '../../models/coverage_check_result.dart';
import '../../models/next_action_model.dart';
import '../../models/paginated_result.dart';
import '../../models/timeline_entry_model.dart';
import '../../repositories/lead_repository.dart';
import '../../../features/get_lead/get_lead_dashboard_data.dart';
import 'mock_data_generators.dart';

class MockLeadRepository implements LeadRepository {
  late final List<LeadModel> _leads;
  late final List<LeadModel> _pool;
  final Map<String, List<TimelineEntryModel>> _extraTimeline = {};

  /// Per-RM log of pool-claim timestamps (mock-only; in prod this lives in a
  /// claims table). Used to compute rolling 7-day window and ITD totals.
  final Map<String, List<DateTime>> _claimLog = {};

  /// Tracks the subset of lead ids that originated from the pool (claimed).
  /// Used to compute "Pool Leads Converted to Clients" ITD.
  final Set<String> _poolOriginLeadIds = {};

  MockLeadRepository() {
    _leads = MockDataGenerators.generateLeads(150);
    _pool = MockDataGenerators.generatePoolLeads(50);
    _seedDemoScenarios();
  }

  void _seedDemoScenarios() {
    final now = DateTime.now();
    // Scenario B — Non-Individual ("Trust" entity type)
    _leads.insert(0, LeadModel(
      id: 'LEAD_B',
      entityType: LeadEntityType.trust,
      fullName: 'Green Earth Foundation',
      phone: '0000000000',
      source: LeadSource.referral,
      stage: LeadStage.lead,
      score: 40,
      assignedRmId: 'RM001',
      assignedRmName: 'Priya Sharma',
      vertical: 'EWG',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ));
    // Scenario D — Lead claimed 2 hours ago ("Newly Claimed" badge)
    _leads.insert(0, LeadModel(
      id: 'LEAD_D',
      fullName: 'Rohit Agarwal',
      phone: '0000000000',
      source: LeadSource.referral,
      stage: LeadStage.lead,
      score: 55,
      assignedRmId: 'RM001',
      assignedRmName: 'Priya Sharma',
      vertical: 'PWG',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ));
    // Scenario L — TL-created wealth leads (shows "My Lead" badge for TL001)
    for (var i = 0; i < 3; i++) {
      _leads.insert(0, LeadModel(
        id: 'LEAD_L${i + 1}',
        fullName: ['Amrita Desai', 'Sanjay Mhatre', 'Farhan Sheikh'][i],
        phone: '0000000000',
        source: LeadSource.referral,
        stage: [LeadStage.lead, LeadStage.profiling, LeadStage.engage][i],
        score: [45, 62, 78][i],
        assignedRmId: 'TL001',
        assignedRmName: 'Vikram Shah',
        vertical: 'EWG',
        createdAt: now.subtract(Duration(days: i + 1)),
        updatedAt: now.subtract(Duration(days: i + 1)),
      ));
    }
  }

  @override
  Future<PaginatedResult<LeadModel>> getLeads({
    int page = 1,
    int pageSize = 20,
    LeadStage? stage,
    LeadTemperature? temperature,
    LeadSource? source,
    String? searchQuery,
    String? sortBy,
    bool ascending = false,
    String? assignedRmId,
    String? assignedTeamId,
    String? region,
    String? zone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<LeadModel>.from(_leads);

    if (assignedRmId != null) {
      filtered = filtered.where((l) => l.assignedRmId == assignedRmId).toList();
    }
    // Hierarchical scope filters — derive team/region/zone from the lead's
    // assigned RM by looking up the user in the mock user list. Each filter
    // is applied independently so callers can layer them if needed (the
    // cubit normally passes only one).
    if (assignedTeamId != null) {
      filtered = filtered.where((l) {
        final u = MockDataGenerators.findUserById(l.assignedRmId);
        return u?.teamId == assignedTeamId;
      }).toList();
    }
    if (region != null) {
      filtered = filtered.where((l) {
        final u = MockDataGenerators.findUserById(l.assignedRmId);
        return u?.regionName == region;
      }).toList();
    }
    if (zone != null) {
      filtered = filtered.where((l) {
        final u = MockDataGenerators.findUserById(l.assignedRmId);
        return u?.zoneName == zone;
      }).toList();
    }
    if (stage != null) {
      filtered = filtered.where((l) => l.stage == stage).toList();
    }
    if (temperature != null) {
      filtered = filtered.where((l) => l.temperature == temperature).toList();
    }
    if (source != null) {
      filtered = filtered.where((l) => l.source == source).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      // Search by name / company / group only (#1). No phone / email.
      bool nameMatch(String name) {
        final n = name.toLowerCase();
        if (n.contains(q)) return true;
        return n.split(RegExp(r'\s+')).any((t) => t.startsWith(q));
      }
      filtered = filtered.where((l) =>
          nameMatch(l.fullName) ||
          (l.companyName?.toLowerCase().contains(q) ?? false) ||
          (l.groupName?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Sort (#4 — 4 options only)
    switch (sortBy) {
      case 'name':
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'aum':
        filtered.sort((a, b) {
          final aAum = a.estimatedAum ?? 0;
          final bAum = b.estimatedAum ?? 0;
          return bAum.compareTo(aAum);
        });
        break;
      case 'created_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'created_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        filtered.sort((a, b) => b.score.compareTo(a.score));
    }

    final total = filtered.length;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);
    final items = start < total ? filtered.sublist(start, end) : <LeadModel>[];

    return PaginatedResult(
      items: items,
      totalCount: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<LeadModel> getLeadById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leads.firstWhere((l) => l.id == id);
  }

  @override
  Future<LeadModel> createLead(LeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _leads.insert(0, lead);
    return lead;
  }

  @override
  Future<LeadModel> updateLead(LeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _leads.indexWhere((l) => l.id == lead.id);
    if (index >= 0) _leads[index] = lead;
    return lead;
  }

  @override
  Future<LeadModel> updateLeadStage(String id, LeadStage newStage, {String? reason, String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _leads.indexWhere((l) => l.id == id);
    if (index >= 0) {
      _leads[index] = _leads[index].copyWith(
        stage: newStage,
        updatedAt: DateTime.now(),
      );
    }
    return _leads[index];
  }

  @override
  Future<LeadModel> markLost(String id, LossReason reason, {String? notes, DateTime? reopenDate}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _leads.indexWhere((l) => l.id == id);
    final lostStage = reason == LossReason.competitor
        ? LeadStage.lostCompetitor
        : reason == LossReason.notInterested
            ? LeadStage.lostNotInterested
            : LeadStage.lostTiming;
    if (index >= 0) {
      _leads[index] = _leads[index].copyWith(
        stage: lostStage,
        updatedAt: DateTime.now(),
      );
    }
    return _leads[index];
  }

  @override
  Future<LeadModel> parkLead(String id, ParkReason reason, DateTime followUpDate, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _leads.indexWhere((l) => l.id == id);
    if (index >= 0) {
      _leads[index] = _leads[index].copyWith(
        stage: LeadStage.parked,
        nextFollowUp: followUpDate,
        updatedAt: DateTime.now(),
      );
    }
    return _leads[index];
  }

  @override
  Future<CoverageCheckResult> checkCoverage(String phone, {String? pan}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final hash = phone.hashCode.abs();
    if (hash % 10 < 7) return CoverageCheckResult.clear();
    final dummy = ClientMasterRecord(
      id: 'CM_DUMMY',
      clientName: 'Existing Client',
      rmName: 'Another RM',
      source: hash % 10 < 9
          ? CoverageSource.clientMaster
          : CoverageSource.leadList,
      lastUpdated: DateTime.now(),
    );
    if (hash % 10 < 9) return CoverageCheckResult.existingClient(dummy);
    return CoverageCheckResult.duplicateLead(dummy);
  }

  @override
  Future<LeadModel> setNextAction(
    String leadId,
    NextActionModel? action,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx < 0) throw StateError('Lead not found: $leadId');
    _leads[idx] = _leads[idx].copyWith(
      nextAction: action,
      clearNextAction: action == null,
      updatedAt: DateTime.now(),
    );
    return _leads[idx];
  }

  @override
  Future<LeadModel> addStatusUpdate(
    String leadId, {
    required LeadUpdateStatus status,
    String? notes,
    required String authorId,
    required String authorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx < 0) throw StateError('Lead not found: $leadId');
    final entry = TimelineEntryModel(
      id: '${leadId}_UPD_${DateTime.now().millisecondsSinceEpoch}',
      leadId: leadId,
      type: TimelineEntryType.statusUpdate,
      dateTime: DateTime.now(),
      title: 'Status: ${status.label}',
      subtitle: notes,
      authorName: authorName,
    );
    _extraTimeline.putIfAbsent(leadId, () => []).insert(0, entry);
    _leads[idx] = _leads[idx].copyWith(
      latestStatus: status,
      updatedAt: DateTime.now(),
      lastContactedAt: DateTime.now(),
    );
    return _leads[idx];
  }

  @override
  Future<List<TimelineEntryModel>> getTimeline(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final lead = _leads.firstWhere(
      (l) => l.id == leadId,
      orElse: () => throw StateError('Lead not found: $leadId'),
    );
    final entries = <TimelineEntryModel>[];
    for (final a in lead.recentActivities) {
      entries.add(TimelineEntryModel(
        id: a.id,
        leadId: leadId,
        type: a.isSystemGenerated
            ? TimelineEntryType.systemEvent
            : TimelineEntryType.activity,
        dateTime: a.dateTime,
        title: a.type.label,
        subtitle: a.outcome != null ? a.outcome!.label : null,
        notes: a.notes,
        authorName: a.loggedByName,
      ));
    }
    entries.addAll(_extraTimeline[leadId] ?? const []);
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return entries;
  }

  @override
  Future<void> appendTimelineEntry(TimelineEntryModel entry) async {
    _extraTimeline.putIfAbsent(entry.leadId, () => []).insert(0, entry);
    final idx = _leads.indexWhere((l) => l.id == entry.leadId);
    if (idx >= 0) {
      _leads[idx] = _leads[idx].copyWith(updatedAt: DateTime.now());
    }
  }

  // ── Drop / Return to Pool ────────────────────────────────────────────

  @override
  Future<LeadModel> dropLead(
    String leadId, {
    DropReason? reason,
    required String notes,
    required String droppedByUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx < 0) throw StateError('Lead not found: $leadId');
    _leads[idx] = _leads[idx].copyWith(
      stage: LeadStage.dropped,
      previousStage: _leads[idx].stage,
      dropReason: reason,
      dropNotes: notes,
      droppedAt: DateTime.now(),
      droppedByUserId: droppedByUserId,
      updatedAt: DateTime.now(),
    );
    return _leads[idx];
  }

  @override
  Future<LeadModel> returnDroppedToPool(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx < 0) throw StateError('Lead not found: $leadId');
    final lead = _leads.removeAt(idx);
    final poolLead = lead.copyWith(
      stage: LeadStage.lead,
      assignedRmId: 'POOL',
      assignedRmName: 'Shared Pool',
      returnToPoolApproved: true,
      updatedAt: DateTime.now(),
    );
    _pool.add(poolLead);
    return poolLead;
  }

  @override
  Future<List<LeadModel>> getDroppedLeads() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leads.where((l) => l.stage == LeadStage.dropped).toList();
  }

  @override
  Future<List<LeadModel>> getPoolLeads() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<LeadModel>.from(_pool);
  }

  // ── Pool / Get Lead ─────────────────────────────────────────────────

  bool _matchesPoolFilters(
    LeadModel lead, {
    String? vertical,
    String? aumBand,
    String? source,
  }) {
    if (vertical != null && vertical.isNotEmpty && lead.vertical != vertical) {
      return false;
    }
    if (source != null && source.isNotEmpty && lead.source.label != source) {
      return false;
    }
    if (aumBand != null && aumBand.isNotEmpty) {
      final aum = lead.estimatedAum ?? 0;
      switch (aumBand) {
        case '<10L':
          if (aum >= 1000000) return false;
          break;
        case '10-50L':
          if (aum < 1000000 || aum >= 5000000) return false;
          break;
        case '50L-1Cr':
          if (aum < 5000000 || aum >= 10000000) return false;
          break;
        case '1Cr+':
          if (aum < 10000000) return false;
          break;
      }
    }
    return true;
  }

  @override
  Future<int> getPoolCount({
    String? vertical,
    String? aumBand,
    String? source,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _pool
        .where((l) => _matchesPoolFilters(
              l,
              vertical: vertical,
              aumBand: aumBand,
              source: source,
            ))
        .length;
  }

  @override
  Future<Map<String, int>> getPoolBreakdown() async {
    await Future.delayed(const Duration(milliseconds: 120));
    final map = <String, int>{};
    for (final lead in _pool) {
      map[lead.vertical] = (map[lead.vertical] ?? 0) + 1;
      final src = lead.source.label;
      map['SRC:$src'] = (map['SRC:$src'] ?? 0) + 1;
    }
    return map;
  }

  @override
  Future<int> addPoolLeads(List<LeadModel> leads) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _pool.addAll(leads);
    return leads.length;
  }

  @override
  Future<LeadModel?> peekNextFromPool({
    String? vertical,
    String? aumBand,
    String? source,
    Set<String> excludeIds = const {},
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    for (final lead in _pool) {
      if (excludeIds.contains(lead.id)) continue;
      if (_matchesPoolFilters(
        lead,
        vertical: vertical,
        aumBand: aumBand,
        source: source,
      )) {
        return lead;
      }
    }
    return null;
  }

  @override
  Future<LeadModel> claimFromPool(
    String leadId,
    String rmId,
    String rmName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final idx = _pool.indexWhere((l) => l.id == leadId);
    if (idx < 0) throw StateError('Lead not in pool: $leadId');
    final claimed = _pool.removeAt(idx).copyWith(
          assignedRmId: rmId,
          assignedRmName: rmName,
          updatedAt: DateTime.now(),
        );
    _leads.insert(0, claimed);
    _claimLog.putIfAbsent(rmId, () => []).add(DateTime.now());
    _poolOriginLeadIds.add(claimed.id);
    return claimed;
  }

  @override
  Future<List<LeadModel>> claimBatchFromPool({
    required String rmId,
    required String rmName,
    required int count,
  }) async {
    if (count <= 0) return const [];
    // Weekly cap retired in the demo-ready batch — no gate. Caller is
    // limited only by the size of the pool itself.
    await Future.delayed(const Duration(milliseconds: 400));
    final claimed = <LeadModel>[];
    for (var i = 0; i < count; i++) {
      if (_pool.isEmpty) break;
      final lead = _pool.removeAt(0).copyWith(
            assignedRmId: rmId,
            assignedRmName: rmName,
            updatedAt: DateTime.now(),
          );
      _leads.insert(0, lead);
      _claimLog.putIfAbsent(rmId, () => []).add(DateTime.now());
      _poolOriginLeadIds.add(lead.id);
      claimed.add(lead);
    }
    return claimed;
  }

  @override
  Future<GetLeadDashboardData> getLeadDashboard(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final log = _claimLog[rmId] ?? const [];
    final convertedFromRequested = _leads
        .where((l) =>
            _poolOriginLeadIds.contains(l.id) &&
            l.assignedRmId == rmId &&
            l.stage == LeadStage.onboard)
        .length;
    return GetLeadDashboardData(
      totalPoolLeads: _pool.length,
      leadsRequestedItd: log.length,
      poolLeadsConvertedItd: convertedFromRequested,
    );
  }

  @override
  Future<Map<LeadStage, int>> getPipelineSummary(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final myLeads = _leads.where((l) => l.assignedRmId == rmId && l.stage.isActive);
    final summary = <LeadStage, int>{};
    for (final stage in LeadStage.activePipeline) {
      summary[stage] = myLeads.where((l) => l.stage == stage).length;
    }
    return summary;
  }
}
