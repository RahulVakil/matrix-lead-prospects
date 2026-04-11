import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';

class GetLeadFilters extends Equatable {
  final String? vertical; // 'EWG' / 'PWG' / null=Any
  final String? aumBand;  // '<10L' / '10-50L' / '50L-1Cr' / '1Cr+' / null
  final String? source;   // source label / null

  const GetLeadFilters({this.vertical, this.aumBand, this.source});

  GetLeadFilters copyWith({
    String? vertical,
    bool clearVertical = false,
    String? aumBand,
    bool clearAumBand = false,
    String? source,
    bool clearSource = false,
  }) {
    return GetLeadFilters(
      vertical: clearVertical ? null : (vertical ?? this.vertical),
      aumBand: clearAumBand ? null : (aumBand ?? this.aumBand),
      source: clearSource ? null : (source ?? this.source),
    );
  }

  @override
  List<Object?> get props => [vertical, aumBand, source];
}

class GetLeadState extends Equatable {
  final bool isLoading;
  final int totalAvailable;
  final int filteredAvailable;
  final Map<String, int> breakdown;
  final GetLeadFilters filters;
  final LeadModel? preview;
  final Set<String> skippedIds;
  final List<LeadModel> recentClaims;
  final String? error;

  const GetLeadState({
    this.isLoading = true,
    this.totalAvailable = 0,
    this.filteredAvailable = 0,
    this.breakdown = const {},
    this.filters = const GetLeadFilters(),
    this.preview,
    this.skippedIds = const {},
    this.recentClaims = const [],
    this.error,
  });

  GetLeadState copyWith({
    bool? isLoading,
    int? totalAvailable,
    int? filteredAvailable,
    Map<String, int>? breakdown,
    GetLeadFilters? filters,
    LeadModel? preview,
    bool clearPreview = false,
    Set<String>? skippedIds,
    List<LeadModel>? recentClaims,
    String? error,
  }) {
    return GetLeadState(
      isLoading: isLoading ?? this.isLoading,
      totalAvailable: totalAvailable ?? this.totalAvailable,
      filteredAvailable: filteredAvailable ?? this.filteredAvailable,
      breakdown: breakdown ?? this.breakdown,
      filters: filters ?? this.filters,
      preview: clearPreview ? null : (preview ?? this.preview),
      skippedIds: skippedIds ?? this.skippedIds,
      recentClaims: recentClaims ?? this.recentClaims,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        totalAvailable,
        filteredAvailable,
        filters,
        preview?.id,
        skippedIds.length,
        recentClaims.length,
        error,
      ];
}

class GetLeadCubit extends Cubit<GetLeadState> {
  final LeadRepository _repo = getIt<LeadRepository>();

  GetLeadCubit() : super(const GetLeadState());

  Future<void> init() async {
    emit(state.copyWith(isLoading: true));
    try {
      final total = await _repo.getPoolCount();
      final breakdown = await _repo.getPoolBreakdown();
      final preview = await _repo.peekNextFromPool();
      emit(state.copyWith(
        isLoading: false,
        totalAvailable: total,
        filteredAvailable: total,
        breakdown: breakdown,
        preview: preview,
        clearPreview: preview == null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> setVertical(String? v) async {
    emit(state.copyWith(filters: state.filters.copyWith(vertical: v, clearVertical: v == null)));
    await _refilter();
  }

  Future<void> setAum(String? v) async {
    emit(state.copyWith(filters: state.filters.copyWith(aumBand: v, clearAumBand: v == null)));
    await _refilter();
  }

  Future<void> setSource(String? v) async {
    emit(state.copyWith(filters: state.filters.copyWith(source: v, clearSource: v == null)));
    await _refilter();
  }

  Future<void> _refilter() async {
    final f = state.filters;
    final filteredCount = await _repo.getPoolCount(
      vertical: f.vertical,
      aumBand: f.aumBand,
      source: f.source,
    );
    final preview = await _repo.peekNextFromPool(
      vertical: f.vertical,
      aumBand: f.aumBand,
      source: f.source,
      excludeIds: state.skippedIds,
    );
    emit(state.copyWith(
      filteredAvailable: filteredCount,
      preview: preview,
      clearPreview: preview == null,
    ));
  }

  Future<void> skip() async {
    final cur = state.preview;
    if (cur == null) return;
    final newSkipped = {...state.skippedIds, cur.id};
    emit(state.copyWith(skippedIds: newSkipped));
    await _refilter();
  }

  Future<LeadModel?> claim({required String rmId, required String rmName}) async {
    final cur = state.preview;
    if (cur == null) return null;
    final claimed = await _repo.claimFromPool(cur.id, rmId, rmName);
    final recents = [claimed, ...state.recentClaims].take(5).toList();
    final newSkipped = {...state.skippedIds, claimed.id};
    emit(state.copyWith(
      recentClaims: recents,
      skippedIds: newSkipped,
      totalAvailable: state.totalAvailable - 1,
      filteredAvailable: (state.filteredAvailable - 1).clamp(0, 1 << 31),
    ));
    await _refilter();
    return claimed;
  }
}
