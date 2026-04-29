import '../../models/lead_request.dart';
import '../../repositories/lead_request_repository.dart';
import 'mock_data_generators.dart';

class MockLeadRequestRepository implements LeadRequestRepository {
  final List<LeadRequest> _store = [];

  MockLeadRequestRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    final rms = MockDataGenerators.allRMs;
    if (rms.length < 4) return;
    // Two pending + one already-fulfilled, spread across teams so the
    // Manage Pool Requests tab and Get Lead audit trail both look real on
    // first launch.
    _store.addAll([
      _build(
        id: 'LR_001',
        rm: rms[0],
        count: 5,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      _build(
        id: 'LR_002',
        rm: rms[3],
        count: 3,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      _build(
        id: 'LR_003',
        rm: rms[1],
        count: 4,
        createdAt: now.subtract(const Duration(days: 2)),
        fulfilledAt: now.subtract(const Duration(days: 1, hours: 18)),
        assignedLeadIds: const ['POOL0007', 'POOL0008', 'POOL0009', 'POOL0010'],
        adminName: 'Sonia Parekh',
        adminId: 'ADM001',
      ),
    ]);
  }

  LeadRequest _build({
    required String id,
    required dynamic rm,
    required int count,
    required DateTime createdAt,
    DateTime? fulfilledAt,
    List<String> assignedLeadIds = const [],
    String? adminId,
    String? adminName,
  }) {
    final tl = _findTeamLead(rm.teamId);
    return LeadRequest(
      id: id,
      rmId: rm.id,
      rmName: rm.name,
      teamLeadId: tl?.id,
      teamLeadName: tl?.name,
      teamId: rm.teamId,
      requestedCount: count,
      status: fulfilledAt != null
          ? LeadRequestStatus.fulfilled
          : LeadRequestStatus.pending,
      createdAt: createdAt,
      fulfilledAt: fulfilledAt,
      assignedLeadIds: assignedLeadIds,
      fulfilledByAdminId: adminId,
      fulfilledByAdminName: adminName,
    );
  }

  /// Find the first TL whose teamId matches. Mock has only 2 TLs (T001 and
  /// T003 per the seed) so other teams won't have one — that's OK; the
  /// notification simply skips the TL leg.
  dynamic _findTeamLead(String? teamId) {
    if (teamId == null) return null;
    if (MockDataGenerators.teamLead.teamId == teamId) {
      return MockDataGenerators.teamLead;
    }
    if (MockDataGenerators.teamLead2.teamId == teamId) {
      return MockDataGenerators.teamLead2;
    }
    return null;
  }

  @override
  Future<LeadRequest> create(LeadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _store.insert(0, request);
    return request;
  }

  @override
  Future<List<LeadRequest>> getForRm(String rmId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store.where((r) => r.rmId == rmId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LeadRequest>> getForTeam(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _store.where((r) {
      // Prefer the captured teamId; fall back to deriving from the RM.
      if (r.teamId != null) return r.teamId == teamId;
      final u = MockDataGenerators.findUserById(r.rmId);
      return u?.teamId == teamId;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LeadRequest>> getAllPending() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _store
        .where((r) => r.status == LeadRequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LeadRequest>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return List<LeadRequest>.from(_store)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<LeadRequest> markFulfilled(
    String id, {
    required String adminId,
    required String adminName,
    required List<String> assignedLeadIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _store.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Lead request not found: $id');
    final updated = _store[i].copyWith(
      status: LeadRequestStatus.fulfilled,
      fulfilledAt: DateTime.now(),
      assignedLeadIds: assignedLeadIds,
      fulfilledByAdminId: adminId,
      fulfilledByAdminName: adminName,
    );
    _store[i] = updated;
    return updated;
  }
}
