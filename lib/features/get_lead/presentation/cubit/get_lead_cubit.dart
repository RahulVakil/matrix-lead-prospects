import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/lead_request.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/repositories/lead_request_repository.dart';
import '../../../../core/services/mock/mock_data_generators.dart';
import '../../../../core/services/mock_notification_queue.dart';
import '../../get_lead_dashboard_data.dart';

class GetLeadState extends Equatable {
  final bool isLoading;
  final GetLeadDashboardData? dashboard;
  final int requestedCount;
  /// Audit trail entries for the current viewer:
  ///   - RM: their own requests
  ///   - TL: requests across all RMs in their team
  final List<LeadRequest> requests;
  final String? error;
  final bool isSubmitting;

  const GetLeadState({
    this.isLoading = true,
    this.dashboard,
    this.requestedCount = 1,
    this.requests = const [],
    this.error,
    this.isSubmitting = false,
  });

  GetLeadState copyWith({
    bool? isLoading,
    GetLeadDashboardData? dashboard,
    int? requestedCount,
    List<LeadRequest>? requests,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return GetLeadState(
      isLoading: isLoading ?? this.isLoading,
      dashboard: dashboard ?? this.dashboard,
      requestedCount: requestedCount ?? this.requestedCount,
      requests: requests ?? this.requests,
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
        requests.length,
        error,
        isSubmitting,
      ];
}

class GetLeadCubit extends Cubit<GetLeadState> {
  final LeadRepository _repo = getIt<LeadRepository>();
  final LeadRequestRepository _requestRepo = getIt<LeadRequestRepository>();
  final UserModel viewer;

  /// Soft ceiling on the request quantity stepper. Pool size is no longer
  /// surfaced anywhere on the screen — this just keeps the stepper sane.
  static const int _softCeiling = 50;

  GetLeadCubit({required this.viewer}) : super(const GetLeadState());

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final d = await _repo.getLeadDashboard(viewer.id);
      final reqs = await _loadRequests();
      emit(state.copyWith(
        isLoading: false,
        dashboard: d,
        requests: reqs,
        // Stepper defaults to 1 — no pool-availability hint surfaced.
        requestedCount: 1,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<List<LeadRequest>> _loadRequests() async {
    if (viewer.role == UserRole.teamLead && viewer.teamId != null) {
      return _requestRepo.getForTeam(viewer.teamId!);
    }
    return _requestRepo.getForRm(viewer.id);
  }

  void setRequestedCount(int n) {
    final clamped = n.clamp(0, _softCeiling);
    emit(state.copyWith(requestedCount: clamped));
  }

  /// Submit a new pool-leads request. The request lands as `pending` for
  /// Admin/MIS to fulfil from Manage Pool's Requests tab. RM and TL each
  /// receive an in-app + email notification confirming the raise.
  Future<bool> submitRequest() async {
    final n = state.requestedCount;
    if (n <= 0) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      // Resolve TL of the requesting RM's team. The viewer might be a TL
      // self-requesting — in that case there's no upstream TL to notify.
      final tl = _resolveTeamLead(viewer);
      final id = 'LR_${DateTime.now().millisecondsSinceEpoch}';
      final req = LeadRequest(
        id: id,
        rmId: viewer.id,
        rmName: viewer.name,
        teamLeadId: tl?.id,
        teamLeadName: tl?.name,
        teamId: viewer.teamId,
        requestedCount: n,
        createdAt: DateTime.now(),
      );
      await _requestRepo.create(req);

      // Notification 1 → the requester (RM or TL).
      MockNotificationQueue.pushInApp(
        recipientId: viewer.id,
        recipientName: viewer.name,
        title: 'Lead request raised',
        body:
            'Your request for $n leads has been submitted. You will be notified once leads are mapped.',
        deepLink: '/get-lead',
      );
      MockNotificationQueue.pushEmail(
        to: '${viewer.name.toLowerCase().replaceAll(' ', '.')}@jmfs.in',
        subject: 'Lead request submitted ($n leads)',
        body:
            'Your request for $n leads from the shared pool has been submitted to Admin / MIS for assignment. You will receive a follow-up notification once the leads are mapped.',
      );
      // Notification 2 → the TL, if there is one and it's not the same person.
      if (tl != null && tl.id != viewer.id) {
        MockNotificationQueue.pushInApp(
          recipientId: tl.id,
          recipientName: tl.name,
          title: 'Team request raised',
          body:
              '${viewer.name} requested $n leads. You will be notified once Admin maps the leads.',
          deepLink: '/get-lead',
        );
        MockNotificationQueue.pushEmail(
          to: '${tl.name.toLowerCase().replaceAll(' ', '.')}@jmfs.in',
          subject:
              'Team lead request raised — ${viewer.name} ($n leads)',
          body:
              '${viewer.name} (RM) has submitted a request for $n leads. Admin / MIS will assign the leads from the pool; you will be notified once that happens.',
        );
      }

      // Refresh state.
      final reqs = await _loadRequests();
      final d = await _repo.getLeadDashboard(viewer.id);
      emit(state.copyWith(
        isSubmitting: false,
        dashboard: d,
        requests: reqs,
        requestedCount: 1,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
      return false;
    }
  }

  /// Find a TL for the given user's team. Returns null if no matching TL
  /// exists in the seed (small teams in mock have only some teams TL'd).
  UserModel? _resolveTeamLead(UserModel u) {
    if (u.role == UserRole.teamLead) return u;
    if (u.teamId == null) return null;
    final tl1 = MockDataGenerators.teamLead;
    if (tl1.teamId == u.teamId) return tl1;
    final tl2 = MockDataGenerators.teamLead2;
    if (tl2.teamId == u.teamId) return tl2;
    return null;
  }
}
