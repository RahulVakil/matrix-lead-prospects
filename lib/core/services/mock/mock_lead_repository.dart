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
import 'mock_data_generators.dart';

class MockLeadRepository implements LeadRepository {
  late final List<LeadModel> _leads;
  late final List<LeadModel> _pool;
  final Map<String, List<TimelineEntryModel>> _extraTimeline = {};

  MockLeadRepository() {
    _leads = MockDataGenerators.generateLeads(150);
    _pool = MockDataGenerators.generatePoolLeads(15);
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<LeadModel>.from(_leads);

    if (assignedRmId != null) {
      filtered = filtered.where((l) => l.assignedRmId == assignedRmId).toList();
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
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((l) =>
          l.fullName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.email?.toLowerCase().contains(q) ?? false) ||
          (l.companyName?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Sort
    switch (sortBy) {
      case 'score':
        filtered.sort((a, b) => ascending ? a.score.compareTo(b.score) : b.score.compareTo(a.score));
        break;
      case 'name':
        filtered.sort((a, b) => ascending ? a.fullName.compareTo(b.fullName) : b.fullName.compareTo(a.fullName));
        break;
      case 'lastActivity':
        filtered.sort((a, b) {
          final aTime = a.lastContactedAt ?? DateTime(2000);
          final bTime = b.lastContactedAt ?? DateTime(2000);
          return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
        });
        break;
      case 'aum':
        filtered.sort((a, b) {
          final aAum = a.estimatedAum ?? 0;
          final bAum = b.estimatedAum ?? 0;
          return ascending ? aAum.compareTo(bAum) : bAum.compareTo(aAum);
        });
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
    return claimed;
  }

  @override
  Future<List<LeadModel>> getHotLeads(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leads
        .where((l) => l.assignedRmId == rmId && l.temperature == LeadTemperature.hot && l.isOverdue)
        .toList()
      ..sort((a, b) {
        final aDur = a.timeSinceLastContact?.inHours ?? 999;
        final bDur = b.timeSinceLastContact?.inHours ?? 999;
        return bDur.compareTo(aDur);
      });
  }

  @override
  Future<List<LeadModel>> getFollowUpsDueToday(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leads
        .where((l) => l.assignedRmId == rmId && l.needsFollowUpToday)
        .toList();
  }

  @override
  Future<List<LeadModel>> getNewAssignments(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leads
        .where((l) => l.assignedRmId == rmId && l.isNewAssignment)
        .toList();
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
