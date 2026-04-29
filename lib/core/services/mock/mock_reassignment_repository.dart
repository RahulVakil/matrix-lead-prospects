import '../../models/reassignment_request.dart';
import '../../repositories/reassignment_repository.dart';
import 'mock_data_generators.dart';

class MockReassignmentRepository implements ReassignmentRepository {
  final List<ReassignmentRequest> _store = [];

  MockReassignmentRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    // 3 demo entries so the new tab is non-empty on first launch.
    final rms = MockDataGenerators.allRMs;
    if (rms.length >= 3) {
      _store.addAll([
        ReassignmentRequest(
          id: 'RR_001',
          matchedClientId: 'CM0007',
          matchedClientName: 'Vikram Mehta',
          sourceRmId: rms[1].id,
          sourceRmName: rms[1].name,
          targetRmId: rms[3].id,
          targetRmName: rms[3].name,
          reason: 'Met at industry event; client expressed willingness to switch.',
          createdAt: now.subtract(const Duration(hours: 18)),
        ),
        ReassignmentRequest(
          id: 'RR_002',
          matchedClientId: 'CM0014',
          matchedClientName: 'Priya Bansal',
          sourceRmId: rms[2].id,
          sourceRmName: rms[2].name,
          targetRmId: rms[6].id,
          targetRmName: rms[6].name,
          reason: 'Long-standing relationship; current RM hasn\'t engaged in 6 months.',
          createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        ),
        ReassignmentRequest(
          id: 'RR_003',
          matchedClientId: 'CM0021',
          matchedClientName: 'Rohan Singhania',
          sourceRmId: rms[5].id,
          sourceRmName: rms[5].name,
          targetRmId: rms[8].id,
          targetRmName: rms[8].name,
          reason: 'Family connection; client referred via referral chain.',
          createdAt: now.subtract(const Duration(days: 2, hours: 7)),
        ),
      ]);
    }
  }

  @override
  Future<ReassignmentRequest> create(ReassignmentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _store.insert(0, request);
    return request;
  }

  @override
  Future<List<ReassignmentRequest>> getAllPending() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return _store
        .where((r) => r.status == ReassignmentStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ReassignmentRequest>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 120));
    final all = List<ReassignmentRequest>.from(_store);
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<ReassignmentRequest> approve(
    String id, {
    required String adminId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _store.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Reassignment request not found: $id');
    final updated = _store[i].copyWith(
      status: ReassignmentStatus.approved,
      decidedAt: DateTime.now(),
      decidedByAdminId: adminId,
      decidedByAdminName: adminName,
    );
    _store[i] = updated;
    return updated;
  }

  @override
  Future<ReassignmentRequest> reject(
    String id, {
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _store.indexWhere((r) => r.id == id);
    if (i < 0) throw StateError('Reassignment request not found: $id');
    final updated = _store[i].copyWith(
      status: ReassignmentStatus.rejected,
      rejectionReason: reason,
      decidedAt: DateTime.now(),
      decidedByAdminId: adminId,
      decidedByAdminName: adminName,
    );
    _store[i] = updated;
    return updated;
  }
}
