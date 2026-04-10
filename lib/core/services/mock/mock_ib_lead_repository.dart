import '../../enums/ib_deal_type.dart';
import '../../models/ib_lead_model.dart';
import '../../models/key_contact_model.dart';
import '../../repositories/ib_lead_repository.dart';

class MockIbLeadRepository implements IbLeadRepository {
  final Map<String, IbLeadModel> _store = {};

  MockIbLeadRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _put(IbLeadModel(
      id: 'IBL0001',
      clientName: 'Rajesh Mehta',
      clientCode: 'WS100001',
      companyName: 'Mehta Industries Pvt Ltd',
      contacts: const [
        KeyContactModel(name: 'Rajesh Mehta', designation: 'Promoter & MD'),
        KeyContactModel(name: 'Anita Kapoor', designation: 'CFO'),
      ],
      dealType: IbDealType.ma,
      dealValue: 1500000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonth: 6,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.clientMeeting, IbIdentifiedHow.referral],
      notes: 'Sector consolidation play. Looking at 2-3 strategic targets.',
      isConfidential: true,
      declarationAccepted: true,
      status: IbLeadStatus.pending,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      createdAt: now.subtract(const Duration(days: 2)),
      submittedAt: now.subtract(const Duration(days: 2)),
    ));
  }

  void _put(IbLeadModel lead) => _store[lead.id] = lead;

  String _newId() => 'IBL${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<IbLeadModel> saveDraft(IbLeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final id = lead.id.isEmpty ? _newId() : lead.id;
    final saved = lead.copyWith(id: id, status: IbLeadStatus.draft);
    _put(saved);
    return saved;
  }

  @override
  Future<IbLeadModel> submit(IbLeadModel lead) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = lead.id.isEmpty ? _newId() : lead.id;
    final saved = lead.copyWith(
      id: id,
      status: IbLeadStatus.pending,
      submittedAt: DateTime.now(),
    );
    _put(saved);
    return saved;
  }

  @override
  Future<List<IbLeadModel>> getMyLeads(String createdById) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _store.values
        .where((l) => l.createdById == createdById)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<IbLeadModel>> getPendingForBranchHead(String branchHeadId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _store.values
        .where((l) => l.status == IbLeadStatus.pending)
        .toList()
      ..sort((a, b) => (b.submittedAt ?? b.createdAt).compareTo(a.submittedAt ?? a.createdAt));
  }

  @override
  Future<List<IbLeadModel>> getAllForBranchHead(String branchHeadId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _store.values.toList()
      ..sort((a, b) => (b.submittedAt ?? b.createdAt).compareTo(a.submittedAt ?? a.createdAt));
  }

  @override
  Future<IbLeadModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store[id];
  }

  @override
  Future<IbLeadModel> approve(
    String id, {
    required String branchHeadId,
    required String branchHeadName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final lead = _store[id]!;
    final updated = lead.copyWith(
      status: IbLeadStatus.approved,
      branchHeadId: branchHeadId,
      branchHeadName: branchHeadName,
      decidedAt: DateTime.now(),
    );
    _put(updated);
    return updated;
  }

  @override
  Future<IbLeadModel> sendBack(
    String id, {
    required String branchHeadId,
    required String branchHeadName,
    required String remarks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final lead = _store[id]!;
    final updated = lead.copyWith(
      status: IbLeadStatus.sentBack,
      branchHeadId: branchHeadId,
      branchHeadName: branchHeadName,
      remarks: remarks,
      decidedAt: DateTime.now(),
    );
    _put(updated);
    return updated;
  }
}
