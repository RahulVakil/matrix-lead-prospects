import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../get_lead_dashboard_data.dart';

class GetLeadState extends Equatable {
  final bool isLoading;
  final GetLeadDashboardData? dashboard;
  final int requestedCount;
  final List<LeadModel> recentClaims;
  final String? error;
  final bool isSubmitting;

  const GetLeadState({
    this.isLoading = true,
    this.dashboard,
    this.requestedCount = 1,
    this.recentClaims = const [],
    this.error,
    this.isSubmitting = false,
  });

  GetLeadState copyWith({
    bool? isLoading,
    GetLeadDashboardData? dashboard,
    int? requestedCount,
    List<LeadModel>? recentClaims,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return GetLeadState(
      isLoading: isLoading ?? this.isLoading,
      dashboard: dashboard ?? this.dashboard,
      requestedCount: requestedCount ?? this.requestedCount,
      recentClaims: recentClaims ?? this.recentClaims,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        dashboard?.totalPoolLeads,
        dashboard?.leadsRequestedItd,
        dashboard?.poolLeadsConvertedItd,
        requestedCount,
        recentClaims.length,
        error,
        isSubmitting,
      ];
}

class GetLeadCubit extends Cubit<GetLeadState> {
  final LeadRepository _repo = getIt<LeadRepository>();
  final String rmId;

  GetLeadCubit({required this.rmId}) : super(const GetLeadState());

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final d = await _repo.getLeadDashboard(rmId);
      emit(state.copyWith(
        isLoading: false,
        dashboard: d,
        // Default the request quantity to 1 if the pool has anything.
        requestedCount: d.totalPoolLeads > 0 ? 1 : 0,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setRequestedCount(int n) {
    final maxAvail = state.dashboard?.totalPoolLeads ?? 0;
    final clamped = n.clamp(0, maxAvail);
    emit(state.copyWith(requestedCount: clamped));
  }

  Future<List<LeadModel>> request({required String rmName}) async {
    final n = state.requestedCount;
    if (n <= 0) return const [];
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final claimed = await _repo.claimBatchFromPool(
        rmId: rmId,
        rmName: rmName,
        count: n,
      );
      final d = await _repo.getLeadDashboard(rmId);
      emit(state.copyWith(
        isSubmitting: false,
        dashboard: d,
        requestedCount: d.totalPoolLeads > 0 ? 1 : 0,
      ));
      return claimed;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
      return const [];
    }
  }
}
