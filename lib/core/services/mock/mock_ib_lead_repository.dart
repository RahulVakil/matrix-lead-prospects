import '../../enums/ib_deal_type.dart';
import '../../models/ib_lead_model.dart';
import '../../models/ib_progress_update.dart';
import '../../models/ib_remark_entry.dart';
import '../../models/key_contact_model.dart';
import '../../repositories/ib_lead_repository.dart';

class MockIbLeadRepository implements IbLeadRepository {
  final Map<String, IbLeadModel> _store = {};

  MockIbLeadRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();

    // ── Scenario A — IB lead in RM bucket with unresolved remark (RM-1 demo)
    _put(IbLeadModel(
      id: 'IBL_A',
      clientName: 'Rajesh Mehta',
      clientCode: 'WS100001',
      companyName: 'Mehta Industries Pvt Ltd',
      contacts: const [
        KeyContactModel(name: 'Rajesh Mehta', designation: 'Promoter & MD', mobile: '+91 98765 43210', email: 'rajesh@mehta-ind.com'),
      ],
      industry: IbIndustry.manufacturing,
      dealType: IbDealType.ma,
      dealValue: 1500000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonths: 4,
      notes: 'Sector consolidation play — 2-3 strategic targets.',
      status: IbLeadStatus.sentBack,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      branchHeadId: 'ADM001',
      branchHeadName: 'Sonia Parekh',
      remarks: 'Valuation range unclear. Please provide a clearer estimate and confirm promoter intent.',
      remarkThread: [
        IbRemarkEntry(
          id: 'RMK_A1',
          authorId: 'ADM001',
          authorName: 'Sonia Parekh',
          role: IbRemarkRole.admin,
          text: 'Valuation range unclear. Please provide a clearer estimate and confirm promoter intent.',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      createdAt: now.subtract(const Duration(days: 5)),
      submittedAt: now.subtract(const Duration(days: 5)),
      decidedAt: now.subtract(const Duration(days: 1)),
    ));
    // ── Scenario C — IB lead with 2 Key Contacts filled (RM-4 demo)
    _put(IbLeadModel(
      id: 'IBL_C',
      clientName: 'Vikram Bajaj',
      companyName: 'Bajaj Auto Components Ltd',
      contacts: const [
        KeyContactModel(name: 'Vikram Bajaj', designation: 'Chairman', mobile: '+91 98210 44444', email: 'vikram@bajaj-auto.com'),
        KeyContactModel(name: 'Meera Bajaj', designation: 'CFO', mobile: '+91 98210 55555', email: 'meera@bajaj-auto.com'),
      ],
      industry: IbIndustry.auto,
      dealType: IbDealType.ecm,
      dealValue: 5000000000,
      dealValueRange: IbDealValueRange.above500Cr,
      dealStage: IbDealStage.mandateExpectedSoon,
      timelineMonths: 6,
      notes: 'IPO advisory mandate expected. Family wants to list auto parts division.',
      status: IbLeadStatus.pending,
      createdById: 'RM002',
      createdByName: 'Amit Verma',
      createdAt: now.subtract(const Duration(days: 3)),
      submittedAt: now.subtract(const Duration(days: 3)),
    ));

    // ── Scenario E — IB-tagged client (blocks duplicate IB creation)
    // This lead is "active" so creating another for Vikram Bajaj should be blocked.

    // ── Scenario H — Approved 25 days ago, never updated (approaching 30-day overdue)
    _put(IbLeadModel(
      id: 'IBL_H',
      clientName: 'Suresh Patel',
      companyName: 'Greenfield Solar Pvt Ltd',
      contacts: const [
        KeyContactModel(name: 'Suresh Patel', designation: 'Founder', mobile: '+91 99000 11111', email: 'suresh@greenfield.in'),
      ],
      industry: IbIndustry.energy,
      dealType: IbDealType.privateEquity,
      dealValue: 800000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.earlyExploration,
      timelineMonths: 10,
      notes: 'PE fundraise for solar manufacturing expansion.',
      status: IbLeadStatus.approved,
      createdById: 'RM003',
      createdByName: 'Deepa Nair',
      branchHeadId: 'ADM001',
      branchHeadName: 'Sonia Parekh',
      assignedIbRmId: 'IB001',
      assignedIbRmName: 'Siddharth Kapoor',
      assignedAt: now.subtract(const Duration(days: 25)),
      assignmentCcList: const ['pe-coverage@jmfs.in', 'head.ib@jmfs.in'],
      createdAt: now.subtract(const Duration(days: 35)),
      submittedAt: now.subtract(const Duration(days: 35)),
      decidedAt: now.subtract(const Duration(days: 25)),
    ));

    // ── Scenario I — Approved 31 days ago, never updated (overdue, RM flagged)
    _put(IbLeadModel(
      id: 'IBL_I',
      clientName: 'Kavita Deshmukh',
      companyName: 'StreamBox Media Pvt Ltd',
      contacts: const [
        KeyContactModel(name: 'Kavita Deshmukh', designation: 'CEO', mobile: '+91 98765 22222', email: 'kavita@streambox.in'),
      ],
      industry: IbIndustry.telecom,
      dealType: IbDealType.ipo,
      dealValue: 2000000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonths: 12,
      notes: 'NCD issue for content acquisition.',
      status: IbLeadStatus.approved,
      createdById: 'RM001',
      createdByName: 'Priya Sharma',
      branchHeadId: 'ADM001',
      branchHeadName: 'Sonia Parekh',
      assignedIbRmId: 'IB002',
      assignedIbRmName: 'Riya Tandon',
      assignedAt: now.subtract(const Duration(days: 31)),
      assignmentCcList: const ['dcm-desk@jmfs.in'],
      createdAt: now.subtract(const Duration(days: 40)),
      submittedAt: now.subtract(const Duration(days: 40)),
      decidedAt: now.subtract(const Duration(days: 31)),
    ));

    // ── Scenario J — Approved 35 days ago, never updated (escalated to TL + IB SPOC)
    _put(IbLeadModel(
      id: 'IBL_J',
      companyName: 'Nexus Pharma Ltd',
      contacts: const [
        KeyContactModel(name: 'Dr. Arun Kapoor', designation: 'MD', mobile: '+91 98765 33333', email: 'arun@nexuspharma.com'),
        KeyContactModel(name: 'Rohit Singh', designation: 'VP Finance', mobile: '+91 98765 33334', email: 'rohit@nexuspharma.com'),
      ],
      industry: IbIndustry.pharma,
      dealType: IbDealType.structuredFinance,
      dealValue: 3500000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.mandateReceived,
      timelineMonths: 4,
      notes: 'Structured finance for API manufacturing. Mandate signed.',
      status: IbLeadStatus.approved,
      createdById: 'RM004',
      createdByName: 'Karan Kapoor',
      branchHeadId: 'ADM001',
      branchHeadName: 'Sonia Parekh',
      assignedIbRmId: 'IB001',
      assignedIbRmName: 'Siddharth Kapoor',
      assignedAt: now.subtract(const Duration(days: 35)),
      assignmentCcList: const ['structured@jmfs.in', 'head.ib@jmfs.in'],
      createdAt: now.subtract(const Duration(days: 45)),
      submittedAt: now.subtract(const Duration(days: 45)),
      decidedAt: now.subtract(const Duration(days: 35)),
    ));

    // ── Scenario K — IB lead with 4 status updates (timeline demo)
    _put(IbLeadModel(
      id: 'IBL_K',
      clientName: 'Anand Krishnamurthy',
      companyName: 'TechVista Solutions',
      contacts: const [
        KeyContactModel(name: 'Anand Krishnamurthy', designation: 'CEO', mobile: '+91 90000 77777', email: 'anand@techvista.in'),
      ],
      industry: IbIndustry.technology,
      dealType: IbDealType.ecm,
      dealValue: 1200000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonths: 6,
      notes: 'Pre-IPO advisory. 40% YoY growth.',
      status: IbLeadStatus.approved,
      createdById: 'RM005',
      createdByName: 'Neha Singh',
      branchHeadId: 'ADM001',
      branchHeadName: 'Sonia Parekh',
      assignedIbRmId: 'IB001',
      assignedIbRmName: 'Siddharth Kapoor',
      assignedAt: now.subtract(const Duration(days: 30)),
      progressUpdates: [
        IbProgressUpdate(id: 'IBP_K1', status: IbProgressStatus.inDiscussion, notes: 'Introductory call. Client receptive.', authorId: 'RM005', authorName: 'Neha Singh', createdAt: now.subtract(const Duration(days: 28))),
        IbProgressUpdate(id: 'IBP_K2', status: IbProgressStatus.proposalSent, notes: 'Sent engagement letter + indicative terms.', authorId: 'IB001', authorName: 'Siddharth Kapoor', createdAt: now.subtract(const Duration(days: 21))),
        IbProgressUpdate(id: 'IBP_K3', status: IbProgressStatus.onHold, notes: 'Client requested 2-week pause for board approval.', authorId: 'RM005', authorName: 'Neha Singh', createdAt: now.subtract(const Duration(days: 14))),
        IbProgressUpdate(id: 'IBP_K4', status: IbProgressStatus.inDiscussion, notes: 'Board approved. Resuming mandate discussions.', authorId: 'IB001', authorName: 'Siddharth Kapoor', createdAt: now.subtract(const Duration(days: 5))),
      ],
      createdAt: now.subtract(const Duration(days: 35)),
      submittedAt: now.subtract(const Duration(days: 35)),
      decidedAt: now.subtract(const Duration(days: 30)),
    ));

    // ── Scenario: Dropped lead for filter demo
    _put(IbLeadModel(
      id: 'IBL_DROP',
      companyName: 'NorthStar Logistics LLP',
      contacts: const [KeyContactModel(name: 'Aman Khanna', designation: 'CFO', mobile: '+91 90000 88888', email: 'aman@northstar.in')],
      dealType: IbDealType.ipo,
      dealValue: 350000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.activeDiscussion,
      timelineMonths: 8,
      notes: 'Promoter shelved fundraise post merger.',
      status: IbLeadStatus.dropped,
      createdById: 'RM002',
      createdByName: 'Amit Verma',
      remarks: 'Lead closed by RM — promoter merger filing.',
      createdAt: now.subtract(const Duration(days: 18)),
      submittedAt: now.subtract(const Duration(days: 18)),
      decidedAt: now.subtract(const Duration(days: 4)),
    ));

    // ── Scenario L — TL-created IB leads (TL-2 "My Lead" badge demo)
    // These are created by TL001 (Vikram Shah) so they show "My Lead" badge.
    _put(IbLeadModel(
      id: 'IBL_L1',
      companyName: 'Shah Textiles Pvt Ltd',
      contacts: const [KeyContactModel(name: 'Dinesh Shah', designation: 'Promoter', mobile: '+91 98210 99999', email: 'dinesh@shahtextiles.in')],
      industry: IbIndustry.fmcg,
      dealType: IbDealType.ma,
      dealValue: 900000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      dealStage: IbDealStage.earlyExploration,
      timelineMonths: 8,
      notes: 'TL-initiated lead — textile consolidation play.',
      status: IbLeadStatus.pending,
      createdById: 'TL001',
      createdByName: 'Vikram Shah',
      createdAt: now.subtract(const Duration(days: 2)),
      submittedAt: now.subtract(const Duration(days: 2)),
    ));
    _put(IbLeadModel(
      id: 'IBL_L2',
      companyName: 'Pune Chemical Works',
      contacts: const [KeyContactModel(name: 'Rajiv Kulkarni', designation: 'MD', mobile: '+91 98230 11111', email: 'rajiv@pcw.com')],
      industry: IbIndustry.manufacturing,
      dealType: IbDealType.privateEquity,
      dealValue: 600000000,
      dealValueRange: IbDealValueRange.range100To500Cr,
      timelineMonths: 6,
      status: IbLeadStatus.pending,
      createdById: 'TL001',
      createdByName: 'Vikram Shah',
      createdAt: now.subtract(const Duration(days: 1)),
      submittedAt: now.subtract(const Duration(days: 1)),
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
