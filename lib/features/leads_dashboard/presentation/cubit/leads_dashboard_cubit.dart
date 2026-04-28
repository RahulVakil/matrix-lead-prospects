import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/repositories/lead_repository.dart';

class LeadsDashboardState extends Equatable {
  final bool isLoading;
  final int totalLeads;
  final int hotCount;
  final int warmCount;
  final int coldCount;
  final int droppedCount;
  final Map<LeadStage, int> pipeline;
  final List<IbLeadModel> ibSentBack;
  final String? error;

  const LeadsDashboardState({
    this.isLoading = true,
    this.totalLeads = 0,
    this.hotCount = 0,
    this.warmCount = 0,
    this.coldCount = 0,
    this.droppedCount = 0,
    this.pipeline = const {},
    this.ibSentBack = const [],
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
  List<Object?> get props => [isLoading, totalLeads, hotCount, warmCount, coldCount, droppedCount, pipeline, ibSentBack.length, error];
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
      ]);

      final allLeads = (results[0] as dynamic).items as List<LeadModel>;
      final pipeline = results[1] as Map<LeadStage, int>;

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

      final droppedC = allLeads.where((l) => l.stage == LeadStage.dropped).length;

      // IB sent-back leads for this RM
      List<IbLeadModel> ibSentBack = [];
      try {
        final ibRepo = getIt<IbLeadRepository>();
        final myIb = await ibRepo.getMyLeads(rmId);
        ibSentBack = myIb.where((l) => l.status == IbLeadStatus.sentBack).toList();
      } catch (_) {}

      emit(LeadsDashboardState(
        isLoading: false,
        totalLeads: allLeads.where((l) => l.stage.isActive).length,
        hotCount: hotC,
        warmCount: warmC,
        coldCount: coldC,
        droppedCount: droppedC,
        pipeline: pipeline,
        ibSentBack: ibSentBack,
      ));
    } catch (e) {
      emit(LeadsDashboardState(isLoading: false, error: e.toString()));
    }
  }
}
