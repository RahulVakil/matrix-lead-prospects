import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/next_action_model.dart';
import '../../../../core/repositories/lead_repository.dart';

/// Reason an item appears on Today, ranked from most to least urgent.
enum TodayReason {
  overdueCallback('Callback overdue', 0),
  callbackToday('Callback today', 1),
  meetingToday('Meeting today', 1),
  followUpDue('Follow-up due', 2),
  newOvernight('New overnight', 3),
  hotInactive('Hot · no contact', 4),
  proposalDue('Proposal pending', 5);

  final String label;
  final int rank;
  const TodayReason(this.label, this.rank);
}

class TodayItem extends Equatable {
  final LeadModel lead;
  final TodayReason reason;
  final NextActionModel? nextAction;

  const TodayItem({
    required this.lead,
    required this.reason,
    this.nextAction,
  });

  @override
  List<Object?> get props => [lead.id, reason];
}

class HomeState extends Equatable {
  final bool isLoading;
  final List<TodayItem> todayItems;
  final List<TodayItem> dueNowItems;
  final Map<LeadStage, int> pipelineSummary;
  final String? error;

  const HomeState({
    this.isLoading = true,
    this.todayItems = const [],
    this.dueNowItems = const [],
    this.pipelineSummary = const {},
    this.error,
  });

  int get totalLeads => pipelineSummary.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [
        isLoading,
        todayItems.length,
        dueNowItems.length,
        pipelineSummary,
        error,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  final String rmId;
  final LeadRepository _repo = getIt<LeadRepository>();

  HomeCubit({required this.rmId}) : super(const HomeState());

  Future<void> loadData() async {
    emit(const HomeState(isLoading: true));
    try {
      final results = await Future.wait([
        _repo.getHotLeads(rmId),
        _repo.getFollowUpsDueToday(rmId),
        _repo.getNewAssignments(rmId),
        _repo.getPipelineSummary(rmId),
        _repo.getLeads(page: 1, pageSize: 200, assignedRmId: rmId),
      ]);

      final hot = results[0] as List<LeadModel>;
      final followUps = results[1] as List<LeadModel>;
      final newOnes = results[2] as List<LeadModel>;
      final allLeads = (results[4] as dynamic).items as List<LeadModel>;

      final byId = <String, TodayItem>{};

      // Layer 1 — leads with a NextAction whose dueAt is overdue or today
      final today0 = DateTime.now();
      final dayStart = DateTime(today0.year, today0.month, today0.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      for (final l in allLeads) {
        final na = l.nextAction;
        if (na == null || na.dueAt == null) continue;
        if (na.isOverdue) {
          byId[l.id] = TodayItem(
            lead: l,
            reason: TodayReason.overdueCallback,
            nextAction: na,
          );
        } else if (na.dueAt!.isAfter(dayStart) && na.dueAt!.isBefore(dayEnd)) {
          byId[l.id] = TodayItem(
            lead: l,
            reason: na.type.label.toLowerCase().contains('meeting')
                ? TodayReason.meetingToday
                : TodayReason.callbackToday,
            nextAction: na,
          );
        }
      }

      // Layer 2 — follow-ups due today (legacy nextFollowUp date)
      for (final l in followUps) {
        byId.putIfAbsent(
          l.id,
          () => TodayItem(lead: l, reason: TodayReason.followUpDue),
        );
      }

      // Layer 3 — new assignments
      for (final l in newOnes) {
        byId.putIfAbsent(
          l.id,
          () => TodayItem(lead: l, reason: TodayReason.newOvernight),
        );
      }

      // Layer 4 — hot leads with no recent contact
      for (final l in hot) {
        byId.putIfAbsent(
          l.id,
          () => TodayItem(lead: l, reason: TodayReason.hotInactive),
        );
      }

      final ranked = byId.values.toList()
        ..sort((a, b) => a.reason.rank.compareTo(b.reason.rank));

      final dueNow = ranked
          .where((i) => i.nextAction?.isDueSoon ?? false)
          .toList();

      emit(HomeState(
        isLoading: false,
        todayItems: ranked,
        dueNowItems: dueNow,
        pipelineSummary: results[3] as Map<LeadStage, int>,
      ));
    } catch (e) {
      emit(HomeState(isLoading: false, error: e.toString()));
    }
  }
}
