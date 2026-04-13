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
    _put(IbLeadModel(
      id: 'IBL0002',
      clientName: 'Vikram Bajaj',
      companyName: 'Bajaj Auto Components Ltd',
      contacts: const [KeyContactModel(name: 'Vikram Bajaj', designation: 'Chairman')],
      dealType: IbDealType.ecm,
      dealValue: 5000000000,
      dealValueRange: IbDealValueRange.above500Cr,
      dealStage: IbDealStage.mandateExpectedSoon,
      timelineMonth: 9,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.industryEvent],
      notes: 'IPO advisory mandate expected. Family wants to list auto parts division.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.approved,
      createdById: 'RM002',
      createdByName: 'Amit Verma',
      createdAt: now.subtract(const Duration(days: 10)),
      submittedAt: now.subtract(const Duration(days: 10)),
      decidedAt: now.subtract(const Duration(days: 7)),
    ));
    _put(IbLeadModel(
      id: 'IBL0003',
      companyName: 'Greenfield Solar Pvt Ltd',
      contacts: const [KeyContactModel(name: 'Suresh Patel', designation: 'Founder')],
      dealType: IbDealType.privateEquity,
      dealValue: 800000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.earlyExploration,
      timelineMonth: 12,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.inboundEnquiry],
      notes: 'PE fundraise for solar manufacturing expansion. Series B.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.pending,
      createdById: 'RM003',
      createdByName: 'Deepa Nair',
      createdAt: now.subtract(const Duration(days: 1)),
      submittedAt: now.subtract(const Duration(days: 1)),
    ));
    _put(IbLeadModel(
      id: 'IBL0004',
      clientName: 'Kavita Deshmukh',
      companyName: 'StreamBox Media Pvt Ltd',
      contacts: const [KeyContactModel(name: 'Kavita Deshmukh', designation: 'CEO')],
      dealType: IbDealType.dcm,
      dealValue: 2000000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonth: 3,
      timelineYear: 2027,
      identifiedHow: const [IbIdentifiedHow.clientMeeting],
      notes: 'NCD issue for content acquisition. Exploring debt structuring.',
      isConfidential: true,
      declarationAccepted: true,
      status: IbLeadStatus.sentBack,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      createdAt: now.subtract(const Duration(days: 5)),
      submittedAt: now.subtract(const Duration(days: 5)),
      decidedAt: now.subtract(const Duration(days: 3)),
      remarks: 'Need more details on the NCD structure and tenure.',
    ));
    _put(IbLeadModel(
      id: 'IBL0005',
      companyName: 'Nexus Pharma Ltd',
      contacts: const [
        KeyContactModel(name: 'Dr. Arun Kapoor', designation: 'MD'),
        KeyContactModel(name: 'Rohit Singh', designation: 'VP Finance'),
      ],
      dealType: IbDealType.structuredFinance,
      dealValue: 3500000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.mandateReceived,
      timelineMonth: 7,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.referral, IbIdentifiedHow.clientMeeting],
      notes: 'Structured finance for API manufacturing facility. Mandate signed.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.forwarded,
      createdById: 'RM004',
      createdByName: 'Karan Kapoor',
      createdAt: now.subtract(const Duration(days: 15)),
      submittedAt: now.subtract(const Duration(days: 15)),
      decidedAt: now.subtract(const Duration(days: 12)),
    ));
    _put(IbLeadModel(
      id: 'IBL0006',
      companyName: 'TechVista Solutions',
      contacts: const [KeyContactModel(name: 'Neha Gupta', designation: 'Co-founder')],
      dealType: IbDealType.ecm,
      dealValue: 1200000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.earlyExploration,
      timelineMonth: 11,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.other],
      notes: 'Pre-IPO advisory. Company growing at 40% YoY.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.draft,
      createdById: 'RM005',
      createdByName: 'Neha Singh',
      createdAt: now.subtract(const Duration(hours: 6)),
    ));
    // Extra sent-back leads for RM001 (Priya Sharma)
    _put(IbLeadModel(
      id: 'IBL0007',
      companyName: 'Arora Steel Industries',
      contacts: const [KeyContactModel(name: 'Rahul Arora', designation: 'MD')],
      dealType: IbDealType.ma,
      dealValue: 2500000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.earlyExploration,
      timelineMonth: 8,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.clientMeeting],
      notes: 'Steel sector consolidation. Arora family exploring exit.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.sentBack,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      createdAt: now.subtract(const Duration(days: 4)),
      submittedAt: now.subtract(const Duration(days: 4)),
      decidedAt: now.subtract(const Duration(days: 2)),
      remarks: 'Valuation range is unclear. Please provide a clearer estimate of the deal size and confirm the family\'s intent to sell.',
    ));
    _put(IbLeadModel(
      id: 'IBL0008',
      companyName: 'Horizon Logistics Pvt Ltd',
      contacts: const [KeyContactModel(name: 'Deepak Jain', designation: 'CEO')],
      dealType: IbDealType.privateEquity,
      dealValue: 600000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonth: 10,
      timelineYear: 2026,
      identifiedHow: const [IbIdentifiedHow.referral],
      notes: 'PE fundraise for logistics tech platform. Growing 50% YoY.',
      isConfidential: false,
      declarationAccepted: true,
      status: IbLeadStatus.sentBack,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      createdAt: now.subtract(const Duration(days: 7)),
      submittedAt: now.subtract(const Duration(days: 7)),
      decidedAt: now.subtract(const Duration(days: 5)),
      remarks: 'Competitor PE fund already in advanced discussions. Need to confirm exclusivity window before IB team engagement.',
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
