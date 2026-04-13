import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/prospect_model.dart';

class ProfilingState extends Equatable {
  final int currentStep; // 0, 1, 2
  final Set<String> geographies;
  final String? netWorthThreshold;
  final Set<String> industries;
  final Set<String> triggerEvents;
  final String? recency;
  final bool isGenerating;
  final bool isComplete;
  final List<ProspectModel> prospects;
  final List<String> talkingPoints;

  const ProfilingState({
    this.currentStep = 0,
    this.geographies = const {},
    this.netWorthThreshold,
    this.industries = const {},
    this.triggerEvents = const {},
    this.recency,
    this.isGenerating = false,
    this.isComplete = false,
    this.prospects = const [],
    this.talkingPoints = const [],
  });

  bool get canAdvanceStep {
    switch (currentStep) {
      case 0:
        return geographies.isNotEmpty && netWorthThreshold != null;
      case 1:
        return triggerEvents.isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  ProfilingState copyWith({
    int? currentStep,
    Set<String>? geographies,
    String? netWorthThreshold,
    Set<String>? industries,
    Set<String>? triggerEvents,
    String? recency,
    bool? isGenerating,
    bool? isComplete,
    List<ProspectModel>? prospects,
    List<String>? talkingPoints,
  }) {
    return ProfilingState(
      currentStep: currentStep ?? this.currentStep,
      geographies: geographies ?? this.geographies,
      netWorthThreshold: netWorthThreshold ?? this.netWorthThreshold,
      industries: industries ?? this.industries,
      triggerEvents: triggerEvents ?? this.triggerEvents,
      recency: recency ?? this.recency,
      isGenerating: isGenerating ?? this.isGenerating,
      isComplete: isComplete ?? this.isComplete,
      prospects: prospects ?? this.prospects,
      talkingPoints: talkingPoints ?? this.talkingPoints,
    );
  }

  @override
  List<Object?> get props => [
        currentStep, geographies.length, netWorthThreshold,
        industries.length, triggerEvents.length, recency,
        isGenerating, isComplete, prospects.length,
      ];
}

class ProfilingCubit extends Cubit<ProfilingState> {
  final String leadName;

  ProfilingCubit({required this.leadName}) : super(const ProfilingState());

  void toggleGeography(String g) {
    final next = {...state.geographies};
    if (!next.remove(g)) next.add(g);
    emit(state.copyWith(geographies: next));
  }

  void setNetWorth(String? v) => emit(state.copyWith(netWorthThreshold: v));

  void toggleIndustry(String i) {
    final next = {...state.industries};
    if (!next.remove(i)) next.add(i);
    emit(state.copyWith(industries: next));
  }

  void toggleTrigger(String t) {
    final next = {...state.triggerEvents};
    if (!next.remove(t)) next.add(t);
    emit(state.copyWith(triggerEvents: next));
  }

  void setRecency(String? v) => emit(state.copyWith(recency: v));

  void nextStep() {
    if (state.currentStep < 2) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  /// Simulate AI-powered prospect generation. In production this would
  /// call Claude API with the selected criteria and do web research.
  Future<void> generate() async {
    emit(state.copyWith(isGenerating: true));
    await Future.delayed(const Duration(milliseconds: 1500));
    emit(state.copyWith(
      isGenerating: false,
      isComplete: true,
      prospects: ProspectModel.mockProspects(),
      talkingPoints: ProspectModel.mockTalkingPoints(leadName),
    ));
  }
}
