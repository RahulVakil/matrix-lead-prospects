import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';

class ActionTodayItem extends Equatable {
  final LeadModel lead;
  final String actionSummary;

  const ActionTodayItem({required this.lead, required this.actionSummary});

  @override
  List<Object?> get props => [lead.id];
}

class LeadsDashboardState extends Equatable {
  final bool isLoading;
  final int totalLeads;
  final int hotCount;
  final int warmCount;
  final int coldCount;
  final int droppedCount;
  final List<ActionTodayItem> actionToday;
  final Map<LeadStage, int> pipeline;
  final String? error;

  const LeadsDashboardState({
    this.isLoading = true,
    this.totalLeads = 0,
    this.hotCount = 0,
    this.warmCount = 0,
    this.coldCount = 0,
    this.droppedCount = 0,
    this.actionToday = const [],
    this.pipeline = const {},
    this.error,
  });

  /// Overall conversion: Lead → Onboarded.
  double get overallConversion {
    final leadCount = pipeline[LeadStage.lead] ?? 0;
    final onboardCount = pipeline[LeadStage.onboard] ?? 0;
    if (leadCount == 0 && onboardCount == 0) return 0;
    final total = leadCount +
        (pipeline[LeadStage.profiling] ?? 0) +
        (pipeline[LeadStage.engage] ?? 0) +
        onboardCount;
    if (total == 0) return 0;
    return (onboardCount / total * 100);
  }

  @override
  List<Object?> get props => [isLoading, totalLeads, hotCount, warmCount, coldCount, droppedCount, actionToday.length, pipeline, error];
}

class LeadsDashboardCubit extends Cubit<LeadsDashboardState> {
  final String rmId;
  final bool isRm; // false = TL/BM/Admin sees all leads
  final LeadRepository _repo = getIt<LeadRepository>();

  LeadsDashboardCubit({required this.rmId, this.isRm = true})
      : super(const LeadsDashboardState());

  Future<void> load() async {
    emit(const LeadsDashboardState(isLoading: true));
    try {
      // RM sees own leads; TL/BM/Admin see all
      final filterRmId = isRm ? rmId : null;
      final results = await Future.wait([
        _repo.getLeads(page: 1, pageSize: 500, assignedRmId: filterRmId),
        _repo.getPipelineSummary(rmId), // pipeline still uses rmId for mock
        _repo.getHotLeads(rmId),
        _repo.getFollowUpsDueToday(rmId),
        _repo.getNewAssignments(rmId),
      ]);

      final allLeads = (results[0] as dynamic).items as List<LeadModel>;
      final pipeline = results[1] as Map<LeadStage, int>;
      final hot = results[2] as List<LeadModel>;
      final followUps = results[3] as List<LeadModel>;
      final newOnes = results[4] as List<LeadModel>;

      // Temperature counts
      var hotC = 0, warmC = 0, coldC = 0;
      for (final l in allLeads) {
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
      }

      // Build action-today items — merge hot + follow-ups + new, dedupe, take top 5
      final seen = <String>{};
      final actions = <ActionTodayItem>[];
      for (final l in hot) {
        if (seen.add(l.id)) {
          actions.add(ActionTodayItem(
            lead: l,
            actionSummary: l.nextAction?.dueDisplay ?? 'Follow up overdue',
          ));
        }
      }
      for (final l in followUps) {
        if (seen.add(l.id)) {
          actions.add(ActionTodayItem(
            lead: l,
            actionSummary: l.nextAction?.dueDisplay ?? 'Follow-up due today',
          ));
        }
      }
      for (final l in newOnes) {
        if (seen.add(l.id)) {
          actions.add(ActionTodayItem(
            lead: l,
            actionSummary: 'New lead — make first contact',
          ));
        }
      }

      final droppedC = allLeads.where((l) => l.stage == LeadStage.dropped).length;

      emit(LeadsDashboardState(
        isLoading: false,
        totalLeads: allLeads.where((l) => l.stage.isActive).length,
        hotCount: hotC,
        warmCount: warmC,
        coldCount: coldC,
        droppedCount: droppedC,
        actionToday: actions,
        pipeline: pipeline,
      ));
    } catch (e) {
      emit(LeadsDashboardState(isLoading: false, error: e.toString()));
    }
  }
}
