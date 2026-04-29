import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/enums/timeframe_filter.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/services/mock/mock_data_generators.dart';

/// One row in the children-breakdown table. Identity + name + scope of the
/// child (used to navigate into it on tap), plus aggregated metrics for the
/// row's own scope (leads / hot / conversions / IB approved).
class ChildBreakdownRow extends Equatable {
  /// `rm` rows route to the RM's `LeadsDashboardScreen`. The other levels
  /// push another `LeadershipDashboardScreen` with the child scope.
  final LeadershipLevel? childLevel;
  final String id;       // teamId / regionName / zoneName / rmId
  final String name;     // display name
  final int leadCount;
  final int hotCount;
  final int conversions; // leads in `onboard` stage within the row's scope
  final int ibApproved;  // IB leads created by RMs in this row's scope (mock-friendly approximation)

  const ChildBreakdownRow({
    required this.childLevel,
    required this.id,
    required this.name,
    required this.leadCount,
    required this.hotCount,
    required this.conversions,
    required this.ibApproved,
  });

  @override
  List<Object?> get props =>
      [childLevel, id, name, leadCount, hotCount, conversions, ibApproved];
}

class ActivityCounts24h extends Equatable {
  final int calls;
  final int meetings;
  final int notes;
  final int stageAdvances;
  final int dropped;

  const ActivityCounts24h({
    this.calls = 0,
    this.meetings = 0,
    this.notes = 0,
    this.stageAdvances = 0,
    this.dropped = 0,
  });

  @override
  List<Object?> get props => [calls, meetings, notes, stageAdvances, dropped];
}

class LeadershipDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final LeadershipLevel level;
  final String? scopeId;
  final String? scopeName;

  // KPI strip
  final int totalLeads;
  final int hotCount;
  final int warmCount;
  final int coldCount;
  final int droppedCount;
  final int ibCount;
  final int conversions; // onboarded
  final int poolCount;
  /// Leads where source == LeadSource.hurun (system-tagged from the Hurun pool).
  final int hurunCount;
  /// Leads where source == LeadSource.monetizationEvent (assigned via JM events).
  final int monetizationEventCount;

  // Pipeline (Lead / Profiling / Engage / Onboarded)
  final Map<LeadStage, int> pipeline;

  // Children breakdown (RMs in team / TLs in region / Regions in zone / Zones in org)
  final List<ChildBreakdownRow> children;

  // Activity counts rolled up over the chosen [timeframe] window.
  final ActivityCounts24h activity;

  // Active timeframe filter — drives the chip row and the `since` cutoff
  // applied to lead and activity aggregations. Default = inception
  // (preserves prior all-time behaviour).
  final TimeframeFilter timeframe;

  const LeadershipDashboardState({
    this.isLoading = true,
    this.error,
    this.level = LeadershipLevel.all,
    this.scopeId,
    this.scopeName,
    this.totalLeads = 0,
    this.hotCount = 0,
    this.warmCount = 0,
    this.coldCount = 0,
    this.droppedCount = 0,
    this.ibCount = 0,
    this.conversions = 0,
    this.poolCount = 0,
    this.hurunCount = 0,
    this.monetizationEventCount = 0,
    this.pipeline = const {},
    this.children = const [],
    this.activity = const ActivityCounts24h(),
    this.timeframe = TimeframeFilter.inception,
  });

  /// Conversion rate (Onboarded / Active total). Returned as a percentage
  /// rounded to one decimal. The Leadership dashboard surfaces this as the
  /// 7th KPI tile alongside the 6 spec'd tiles.
  double get conversionRatePct {
    final active = totalLeads + conversions;
    if (active == 0) return 0;
    return (conversions / active) * 100;
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        level,
        scopeId,
        scopeName,
        totalLeads,
        hotCount,
        warmCount,
        coldCount,
        droppedCount,
        ibCount,
        conversions,
        poolCount,
        hurunCount,
        monetizationEventCount,
        pipeline,
        children.length,
        activity,
        timeframe,
      ];
}

class LeadershipDashboardCubit extends Cubit<LeadershipDashboardState> {
  final LeadRepository _leadRepo = getIt<LeadRepository>();
  final IbLeadRepository _ibRepo = getIt<IbLeadRepository>();

  /// The scope this dashboard is rendering. The screen creates one cubit
  /// per scope (per drill-down level).
  final LeadershipLevel level;
  final String? scopeId;
  final String? scopeName;

  LeadershipDashboardCubit({
    required this.level,
    this.scopeId,
    this.scopeName,
  }) : super(LeadershipDashboardState(
          level: level,
          scopeId: scopeId,
          scopeName: scopeName,
        ));

  Future<void> load({TimeframeFilter? timeframe}) async {
    final tf = timeframe ?? state.timeframe;
    emit(state.copyWith(isLoading: true, timeframe: tf));
    try {
      // Pull the scoped lead set in one shot. Mock repo applies the filter
      // by looking up each lead's assignedRm in the user table.
      final allScoped = await _scopedLeads();

      // Apply the timeframe window: a lead is "active in window" if its
      // createdAt OR lastContactedAt falls at/after `since`. Inception
      // returns null → no slicing, all-time data.
      final since = tf.since;
      final leads = since == null
          ? allScoped
          : allScoped
              .where((l) =>
                  l.createdAt.isAfter(since) ||
                  (l.lastContactedAt?.isAfter(since) ?? false))
              .toList();

      var totalLeads = 0;
      var hotC = 0, warmC = 0, coldC = 0, droppedC = 0, conversions = 0;
      var hurunC = 0, eventC = 0;
      final pipeline = <LeadStage, int>{};
      var calls = 0, meetings = 0, notes = 0, stageAdvances = 0, dropped = 0;
      // Activity rollup uses the same `since` as the lead-window filter.
      // Inception → epoch (counts every activity ever logged).
      final activitySince = since ?? DateTime.fromMillisecondsSinceEpoch(0);

      for (final l in leads) {
        if (l.stage == LeadStage.dropped) {
          droppedC++;
        } else {
          totalLeads++;
        }
        if (l.stage == LeadStage.onboard) conversions++;
        pipeline[l.stage] = (pipeline[l.stage] ?? 0) + 1;
        if (l.source == LeadSource.hurun) hurunC++;
        if (l.source == LeadSource.monetizationEvent) eventC++;
        switch (l.temperature) {
          case LeadTemperature.hot:
            hotC++;
            break;
          case LeadTemperature.warm:
            warmC++;
            break;
          case LeadTemperature.cold:
            coldC++;
            break;
          default:
            break;
        }
        // Activity within the chosen window on this lead's recentActivities feed.
        for (final a in l.recentActivities) {
          if (a.dateTime.isBefore(activitySince)) continue;
          switch (a.type.name) {
            case 'call':
              calls++;
              break;
            case 'meeting':
              meetings++;
              break;
            case 'note':
              notes++;
              break;
            case 'stageAdvance':
              stageAdvances++;
              break;
            case 'dropped':
            case 'drop':
              dropped++;
              break;
          }
        }
      }

      // IB leads in scope — count Approved IB leads owned by RMs in scope.
      // Mock-friendly: we pull all and filter client-side.
      var ibCount = 0;
      try {
        final ibAll = await _ibRepo.getAllForBranchHead('SCOPE');
        for (final ib in ibAll) {
          if (!ib.status.isApproved) continue;
          if (since != null && ib.createdAt.isBefore(since)) continue;
          if (_rmIdInScope(ib.createdById)) ibCount++;
        }
      } catch (_) {}

      // Pool count is a single number; only meaningful at `all` scope where
      // the org-wide pool is shared. For deeper scopes we approximate to 0.
      var poolCount = 0;
      try {
        if (level == LeadershipLevel.all) {
          poolCount = await _leadRepo.getPoolCount();
        }
      } catch (_) {}

      // Build children breakdown rows for the next level down.
      final children = _buildChildrenBreakdown(leads);

      emit(LeadershipDashboardState(
        isLoading: false,
        level: level,
        scopeId: scopeId,
        scopeName: scopeName,
        totalLeads: totalLeads,
        hotCount: hotC,
        warmCount: warmC,
        coldCount: coldC,
        droppedCount: droppedC,
        ibCount: ibCount,
        conversions: conversions,
        poolCount: poolCount,
        hurunCount: hurunC,
        monetizationEventCount: eventC,
        pipeline: pipeline,
        children: children,
        activity: ActivityCounts24h(
          calls: calls,
          meetings: meetings,
          notes: notes,
          stageAdvances: stageAdvances,
          dropped: dropped,
        ),
        timeframe: tf,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Switch the active timeframe and reload. Emits the chip-state echo
  /// immediately so the UI reflects the new selection during the reload.
  Future<void> setTimeframe(TimeframeFilter t) async {
    emit(state.copyWith(timeframe: t));
    await load(timeframe: t);
  }

  Future<List<LeadModel>> _scopedLeads() async {
    // Pull a wide page (mock dataset is small). Pass exactly one filter
    // matching the current level.
    final result = await _leadRepo.getLeads(
      page: 1,
      pageSize: 1000,
      assignedTeamId: level == LeadershipLevel.team ? scopeId : null,
      region: level == LeadershipLevel.region ? scopeId : null,
      zone: level == LeadershipLevel.zone ? scopeId : null,
    );
    return result.items;
  }

  bool _rmIdInScope(String rmId) {
    final u = MockDataGenerators.findUserById(rmId);
    if (u == null) return false;
    switch (level) {
      case LeadershipLevel.team:
        return u.teamId == scopeId;
      case LeadershipLevel.region:
        return u.regionName == scopeId;
      case LeadershipLevel.zone:
        return u.zoneName == scopeId;
      case LeadershipLevel.all:
        return true;
    }
  }

  List<ChildBreakdownRow> _buildChildrenBreakdown(List<LeadModel> leads) {
    // For each level, group leads by the next-level discriminator.
    switch (level) {
      case LeadershipLevel.team:
        return _groupBy(
          leads,
          (l) => l.assignedRmId,
          nameOf: (id) => MockDataGenerators.findUserById(id)?.name ?? id,
          ibScopeMatches: (rmId) => true,
          childLevel: null, // RM rows route to LeadsDashboardScreen
        );
      case LeadershipLevel.region:
        return _groupBy(
          leads,
          (l) {
            final u = MockDataGenerators.findUserById(l.assignedRmId);
            return u?.teamId ?? '—';
          },
          nameOf: (teamId) {
            final u = MockDataGenerators.allRMs
                .firstWhere((r) => r.teamId == teamId,
                    orElse: () => MockDataGenerators.defaultRm);
            return u.teamName ?? teamId;
          },
          ibScopeMatches: (teamId) => true,
          childLevel: LeadershipLevel.team,
        );
      case LeadershipLevel.zone:
        return _groupBy(
          leads,
          (l) {
            final u = MockDataGenerators.findUserById(l.assignedRmId);
            return u?.regionName ?? '—';
          },
          nameOf: (region) => region,
          ibScopeMatches: (region) => true,
          childLevel: LeadershipLevel.region,
        );
      case LeadershipLevel.all:
        return _groupBy(
          leads,
          (l) {
            final u = MockDataGenerators.findUserById(l.assignedRmId);
            return u?.zoneName ?? '—';
          },
          nameOf: (zone) => zone,
          ibScopeMatches: (zone) => true,
          childLevel: LeadershipLevel.zone,
        );
    }
  }

  List<ChildBreakdownRow> _groupBy(
    List<LeadModel> leads,
    String Function(LeadModel) keyOf, {
    required String Function(String) nameOf,
    required bool Function(String) ibScopeMatches,
    required LeadershipLevel? childLevel,
  }) {
    final byKey = <String, List<LeadModel>>{};
    for (final l in leads) {
      final k = keyOf(l);
      if (k == '—') continue;
      byKey.putIfAbsent(k, () => []).add(l);
    }
    final rows = byKey.entries.map((e) {
      final list = e.value;
      final hot =
          list.where((l) => l.temperature == LeadTemperature.hot).length;
      final conv = list.where((l) => l.stage == LeadStage.onboard).length;
      // IB approximation: count IB lead refs on each lead in this group.
      var ib = 0;
      for (final l in list) {
        ib += l.ibLeadIds.length;
      }
      return ChildBreakdownRow(
        childLevel: childLevel,
        id: e.key,
        name: nameOf(e.key),
        leadCount: list.length,
        hotCount: hot,
        conversions: conv,
        ibApproved: ib,
      );
    }).toList();
    rows.sort((a, b) => b.leadCount.compareTo(a.leadCount));
    return rows;
  }
}

extension on LeadershipDashboardState {
  LeadershipDashboardState copyWith({
    bool? isLoading,
    String? error,
    TimeframeFilter? timeframe,
  }) {
    return LeadershipDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      level: level,
      scopeId: scopeId,
      scopeName: scopeName,
      totalLeads: totalLeads,
      hotCount: hotCount,
      warmCount: warmCount,
      coldCount: coldCount,
      droppedCount: droppedCount,
      ibCount: ibCount,
      conversions: conversions,
      poolCount: poolCount,
      hurunCount: hurunCount,
      monetizationEventCount: monetizationEventCount,
      pipeline: pipeline,
      children: children,
      activity: activity,
      timeframe: timeframe ?? this.timeframe,
    );
  }
}

// Imports above use `IbLeadModel` symbol via reference — keep the model
// import to silence the linter even though we don't construct one here.
// ignore: unused_element
void _keepIbLeadModelImport(IbLeadModel _) {}
