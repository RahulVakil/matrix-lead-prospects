import 'dart:math';
import '../../enums/lead_stage.dart';
import '../../enums/lead_source.dart';
import '../../enums/activity_type.dart';
import '../../enums/next_action_type.dart';
import '../../models/lead_model.dart';
import '../../models/activity_model.dart';
import '../../models/client_master_record.dart';
import '../../models/client_model.dart';
import '../../models/deal_info_model.dart';
import '../../models/family_group_model.dart';
import '../../models/next_action_model.dart';
import '../../models/profiling_model.dart';
import '../../models/user_model.dart';
import '../../enums/user_role.dart';

class MockDataGenerators {
  MockDataGenerators._();

  static final _firstNames = [
    'Rajesh', 'Priya', 'Amit', 'Sneha', 'Vikram', 'Anita', 'Suresh',
    'Kavita', 'Rohit', 'Deepa', 'Alok', 'Sunita', 'Manoj', 'Rashmi',
    'Karan', 'Pooja', 'Sanjay', 'Meera', 'Arun', 'Neha', 'Ramesh',
    'Divya', 'Ajay', 'Nandini', 'Vivek', 'Shruti', 'Prakash', 'Rina',
    'Nitin', 'Anjali', 'Gaurav', 'Pallavi', 'Dinesh', 'Swati', 'Ashok',
    'Preeti', 'Harish', 'Rekha', 'Mukesh', 'Savita', 'Rakesh', 'Jaya',
    'Pankaj', 'Lata', 'Sandeep', 'Usha', 'Manish', 'Geeta', 'Vinod', 'Seema',
  ];

  static final _lastNames = [
    'Sharma', 'Patel', 'Mehta', 'Agarwal', 'Joshi', 'Reddy', 'Kumar',
    'Gupta', 'Singh', 'Verma', 'Shah', 'Desai', 'Iyer', 'Nair',
    'Kapoor', 'Malhotra', 'Bhatia', 'Chopra', 'Khanna', 'Saxena',
    'Bansal', 'Garodia', 'Bajaj', 'Singhania', 'Birla', 'Ambani',
    'Tata', 'Mittal', 'Dalmia', 'Jhunjhunwala',
  ];

  static final _companies = [
    'Reliance Industries', 'Tata Consultancy', 'Infosys', 'Wipro',
    'HCL Technologies', 'Bajaj Finance', 'Asian Paints', 'HDFC Ltd',
    'Hindustan Unilever', 'ITC Limited', 'Mahindra Group', 'Adani Enterprises',
    'Godrej Industries', 'Larsen & Toubro', 'Sun Pharma', 'Dr Reddy\'s',
    'Cipla Ltd', 'Bharti Airtel', 'Kotak Mahindra', 'Axis Bank',
    'Tech Mahindra', 'Mphasis', 'Persistent Systems', 'Coforge',
    null, null, null, // Some leads have no company
  ];

  static final _cities = [
    'Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune', 'Hyderabad',
    'Ahmedabad', 'Kolkata', 'Jaipur', 'Chandigarh', 'Lucknow', 'Surat',
    'Indore', 'Noida', 'Gurgaon', 'Thane', 'Navi Mumbai',
  ];

  static final _products = [
    'Mutual Fund', 'PMS', 'AIF', 'Equity', 'Bonds', 'Insurance',
    'Fixed Deposit', 'Real Estate Fund', 'Structured Products',
  ];

  static final _contactTimes = ['Morning', 'Afternoon', 'Evening', 'Any'];

  static final _rmNames = [
    UserModel(id: 'RM001', name: 'Priya Sharma', empCode: 'EMP001', role: UserRole.rm, branchName: 'Mumbai HQ', teamId: 'T001', teamName: 'West Alpha', regionName: 'West', designation: 'Sr. RM'),
    UserModel(id: 'RM002', name: 'Amit Verma', empCode: 'EMP002', role: UserRole.rm, branchName: 'Mumbai HQ', teamId: 'T001', teamName: 'West Alpha', regionName: 'West', designation: 'RM'),
    UserModel(id: 'RM003', name: 'Deepa Nair', empCode: 'EMP003', role: UserRole.rm, branchName: 'Pune', teamId: 'T002', teamName: 'West Beta', regionName: 'West', designation: 'RM'),
    UserModel(id: 'RM004', name: 'Karan Kapoor', empCode: 'EMP004', role: UserRole.rm, branchName: 'Delhi', teamId: 'T003', teamName: 'North Alpha', regionName: 'North', designation: 'Sr. RM'),
    UserModel(id: 'RM005', name: 'Neha Singh', empCode: 'EMP005', role: UserRole.rm, branchName: 'Bangalore', teamId: 'T004', teamName: 'South Alpha', regionName: 'South', designation: 'RM'),
  ];

  static UserModel get defaultRm => _rmNames[0];

  static List<UserModel> get allRMs => List.unmodifiable(_rmNames);

  static UserModel get teamLead => UserModel(
    id: 'TL001', name: 'Vikram Shah', empCode: 'TL001', role: UserRole.teamLead,
    branchName: 'Mumbai HQ', teamId: 'T001', teamName: 'West Alpha', regionName: 'West', designation: 'Team Lead',
  );

  static UserModel get checker => UserModel(
    id: 'CHK001', name: 'Sunita Desai', empCode: 'CHK001', role: UserRole.checker,
    branchName: 'Mumbai HQ', designation: 'Sr. Compliance Officer',
  );

  static UserModel get admin => UserModel(
    id: 'ADM001', name: 'Ramesh Gupta', empCode: 'ADM001', role: UserRole.admin,
    branchName: 'Mumbai HQ', designation: 'MIS Admin',
  );

  static UserModel get branchHead => UserModel(
    id: 'BH001', name: 'Anjali Bhatia', empCode: 'BH001', role: UserRole.branchManager,
    branchName: 'Mumbai HQ', designation: 'Branch Head',
  );

  static List<LeadModel> generateLeads(int count, {String? rmId}) {
    final rng = Random(42); // deterministic seed
    final leads = <LeadModel>[];
    final now = DateTime.now();

    for (var i = 0; i < count; i++) {
      final seed = i;
      final firstName = _firstNames[seed % _firstNames.length];
      final lastName = _lastNames[(seed * 7 + 3) % _lastNames.length];
      final rm = rmId != null
          ? _rmNames.firstWhere((r) => r.id == rmId, orElse: () => _rmNames[seed % _rmNames.length])
          : _rmNames[seed % _rmNames.length];

      final stage = _stageForIndex(seed, rng);
      final source = LeadSource.values[seed % LeadSource.values.length];
      final daysOld = rng.nextInt(90) + 1;
      final createdAt = now.subtract(Duration(days: daysOld));
      final lastContactDaysAgo = stage == LeadStage.lead && rng.nextBool()
          ? null
          : rng.nextInt(daysOld.clamp(1, 30));
      final lastContacted = lastContactDaysAgo != null
          ? now.subtract(Duration(hours: lastContactDaysAgo * 24 + rng.nextInt(24)))
          : null;

      final score = _scoreForLead(source, stage, lastContacted, rng);
      final aum = _aumForIndex(seed, rng);
      final numProducts = rng.nextInt(3) + 1;
      final products = List.generate(numProducts, (j) => _products[(seed + j) % _products.length]).toSet().toList();

      final activities = _generateActivities(
        leadId: 'LEAD${(i + 1).toString().padLeft(4, '0')}',
        count: rng.nextInt(6) + 2,
        rmId: rm.id,
        rmName: rm.name,
        createdAt: createdAt,
        rng: rng,
      );

      DealInfoModel? dealInfo;
      if (stage.order >= 3) {
        dealInfo = DealInfoModel(
          aumEstimate: aum ?? 5000000,
          products: products,
          expectedCloseMonth: 'June 2026',
          probability: 30 + rng.nextInt(60),
        );
      }

      ProfilingModel? profiling;
      if (stage == LeadStage.profiling || stage == LeadStage.onboard) {
        profiling = ProfilingModel(
          id: 'PROF${(i + 1).toString().padLeft(4, '0')}',
          leadId: 'LEAD${(i + 1).toString().padLeft(4, '0')}',
          status: stage == LeadStage.onboard
              ? ProfilingStatus.approved
              : ProfilingStatus.values[rng.nextInt(3) + 2],
          submittedAt: now.subtract(Duration(days: rng.nextInt(10))),
          submittedById: rm.id,
          submittedByName: rm.name,
          kycDocumentsReady: rng.nextBool(),
          suitabilityComplete: rng.nextBool(),
          riskProfileComplete: rng.nextBool(),
        );
      }

      // Sprinkle next-actions on ~40% of leads
      NextActionModel? nextAction;
      if (rng.nextInt(10) < 4 && stage.isActive) {
        final type = NextActionType.values[rng.nextInt(NextActionType.values.length - 1)];
        final hoursOffset = rng.nextInt(48) - 6; // -6h to +42h
        nextAction = NextActionModel(
          type: type,
          dueAt: now.add(Duration(hours: hoursOffset)),
          notes: rng.nextBool() ? 'Discussed in last call' : null,
        );
      }

      leads.add(LeadModel(
        id: 'LEAD${(i + 1).toString().padLeft(4, '0')}',
        fullName: '$firstName $lastName',
        phone: '+91 ${9000000000 + seed * 11111}',
        email: rng.nextBool() ? '${firstName.toLowerCase()}.${lastName.toLowerCase()}@email.com' : null,
        companyName: _companies[(seed * 3) % _companies.length],
        city: _cities[seed % _cities.length],
        source: source,
        referredBy: source == LeadSource.referral ? '${_firstNames[(seed + 5) % _firstNames.length]} ${_lastNames[(seed + 2) % _lastNames.length]}' : null,
        stage: stage,
        score: score,
        estimatedAum: aum,
        productInterest: products,
        assignedRmId: rm.id,
        assignedRmName: rm.name,
        teamLeadId: 'TL001',
        vertical: seed % 3 == 0 ? 'PWG' : 'EWG',
        bestContactTime: _contactTimes[seed % _contactTimes.length],
        notes: seed % 4 == 0 ? 'High-potential prospect from ${source.label}' : null,
        createdAt: createdAt,
        updatedAt: lastContacted ?? createdAt,
        lastContactedAt: lastContacted,
        nextFollowUp: rng.nextInt(3) == 0 ? now.add(Duration(days: rng.nextInt(3))) : null,
        dealInfo: dealInfo,
        profiling: profiling,
        recentActivities: activities,
        nextAction: nextAction,
      ));
    }

    return leads;
  }

  static List<ClientMasterRecord> generateClientMasterRecords() {
    final now = DateTime.now();
    final out = <ClientMasterRecord>[];
    final rng = Random(7);
    for (var i = 0; i < 60; i++) {
      final firstName = _firstNames[i % _firstNames.length];
      final lastName = _lastNames[(i * 5 + 1) % _lastNames.length];
      final company = _companies[i % _companies.length];
      final rm = _rmNames[(i * 3) % _rmNames.length];
      final src = i % 3 == 0
          ? CoverageSource.companyMaster
          : (i % 3 == 1 ? CoverageSource.clientMaster : CoverageSource.leadList);
      out.add(ClientMasterRecord(
        id: 'CM${(i + 1).toString().padLeft(4, '0')}',
        clientName: '$firstName $lastName',
        groupName: company,
        rmName: rm.name,
        rmId: rm.id,
        phone: '+91 ${9000000000 + i * 13571}',
        city: _cities[i % _cities.length],
        source: src,
        lastUpdated: now.subtract(Duration(days: rng.nextInt(180))),
      ));
    }
    return out;
  }

  /// Generates a small "shared pool" of unassigned leads.
  /// Used by the Get Lead workflow — the RM can claim from this pool.
  /// Each lead has assignedRmId/Name set to placeholder POOL values so the
  /// list filtering still works; claimFromPool overwrites them.
  static List<LeadModel> generatePoolLeads(int count) {
    final rng = Random(99);
    final now = DateTime.now();
    final out = <LeadModel>[];
    for (var i = 0; i < count; i++) {
      final firstName = _firstNames[(i * 4 + 7) % _firstNames.length];
      final lastName = _lastNames[(i * 5 + 2) % _lastNames.length];
      final source = LeadSource.values[(i * 3) % LeadSource.values.length];
      final aum = _aumForIndex(i + 5, rng);
      final daysOld = rng.nextInt(20) + 1;
      final createdAt = now.subtract(Duration(days: daysOld));
      out.add(LeadModel(
        id: 'POOL${(i + 1).toString().padLeft(4, '0')}',
        fullName: '$firstName $lastName',
        phone: '+91 ${9100000000 + i * 9876}',
        email: rng.nextBool()
            ? '${firstName.toLowerCase()}.${lastName.toLowerCase()}@email.com'
            : null,
        companyName: _companies[(i * 2 + 1) % _companies.length],
        city: _cities[(i * 3) % _cities.length],
        source: source,
        stage: LeadStage.lead,
        score: source.baseScore + rng.nextInt(20),
        estimatedAum: aum,
        productInterest: [_products[i % _products.length]],
        assignedRmId: 'POOL',
        assignedRmName: 'Shared Pool',
        vertical: i % 2 == 0 ? 'EWG' : 'PWG',
        createdAt: createdAt,
        updatedAt: createdAt,
        recentActivities: const [],
      ));
    }
    return out;
  }

  /// Build family groups from client master records by grouping on groupName.
  static List<FamilyGroupModel> generateFamilyGroups(
    List<ClientMasterRecord> records,
  ) {
    final byGroup = <String, List<ClientMasterRecord>>{};
    for (final r in records) {
      if (r.groupName != null && r.groupName!.isNotEmpty) {
        byGroup.putIfAbsent(r.groupName!, () => []).add(r);
      }
    }

    final rng = Random(21);
    final relationships = ['Self', 'Spouse', 'Parent', 'Child', 'Sibling'];
    final out = <FamilyGroupModel>[];
    var idx = 0;
    for (final entry in byGroup.entries) {
      if (entry.value.length < 2 && rng.nextBool()) continue;
      final members = entry.value.map((r) {
        return FamilyMember(
          name: r.clientName,
          clientCode: r.id,
          phone: r.phone,
          relationship: relationships[rng.nextInt(relationships.length)],
          isClient: r.source == CoverageSource.clientMaster,
          assignedRmName: r.rmName,
        );
      }).toList();

      final extras = rng.nextInt(2) + 1;
      for (var j = 0; j < extras; j++) {
        final fn = _firstNames[(idx * 3 + j * 7) % _firstNames.length];
        final ln = entry.key.split(' ').first;
        members.add(FamilyMember(
          name: '$fn $ln',
          relationship: relationships[(j + 2) % relationships.length],
          isClient: rng.nextBool(),
          assignedRmName: entry.value.first.rmName,
        ));
      }

      final primaryRm = entry.value.first;
      out.add(FamilyGroupModel(
        id: 'FAM${(idx + 1).toString().padLeft(4, '0')}',
        groupName: entry.key,
        members: members,
        primaryRmId: primaryRm.rmId,
        primaryRmName: primaryRm.rmName,
        totalAum: (rng.nextInt(50) + 5) * 1000000.0,
        city: primaryRm.city,
      ));
      idx++;
    }
    return out;
  }

  static List<ClientModel> generateClients(int count) {
    final rng = Random(11);
    final now = DateTime.now();
    final out = <ClientModel>[];
    for (var i = 0; i < count; i++) {
      final firstName = _firstNames[(i * 2 + 1) % _firstNames.length];
      final lastName = _lastNames[(i * 3 + 4) % _lastNames.length];
      final rm = _rmNames[i % _rmNames.length];
      final aum = (rng.nextInt(80) + 5) * 1000000.0;
      final products = List.generate(
        rng.nextInt(3) + 1,
        (j) => _products[(i + j) % _products.length],
      ).toSet().toList();
      out.add(ClientModel(
        id: 'CLT${(i + 1).toString().padLeft(4, '0')}',
        clientCode: 'WS${(100000 + i).toString()}',
        fullName: '$firstName $lastName',
        groupName: _companies[i % _companies.length],
        phone: '+91 ${9000000000 + i * 24681}',
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@email.com',
        city: _cities[i % _cities.length],
        aum: aum,
        products: products,
        assignedRmId: rm.id,
        assignedRmName: rm.name,
        isDirect: i % 4 != 0,
        onboardedAt: now.subtract(Duration(days: rng.nextInt(720) + 30)),
      ));
    }
    return out;
  }

  static LeadStage _stageForIndex(int seed, Random rng) {
    // Distribution: 25% Lead, 30% Engage, 20% Opportunity, 15% Profiling, 5% Client, 5% other
    final roll = (seed * 17 + rng.nextInt(10)) % 100;
    if (roll < 25) return LeadStage.lead;
    if (roll < 55) return LeadStage.engage;
    if (roll < 75) return LeadStage.engage;
    if (roll < 90) return LeadStage.profiling;
    if (roll < 95) return LeadStage.onboard;
    if (roll < 97) return LeadStage.parked;
    return LeadStage.dormant;
  }

  static int _scoreForLead(LeadSource source, LeadStage stage, DateTime? lastContacted, Random rng) {
    var score = source.baseScore;
    // AUM bonus
    score += rng.nextInt(30);
    // Stage bonus
    if (stage.order >= 3) score += 5;
    if (stage.order >= 4) score += 5;
    // Engagement bonus
    score += rng.nextInt(20);
    // Recency decay
    if (lastContacted != null) {
      final daysSince = DateTime.now().difference(lastContacted).inDays;
      if (daysSince > 30) score -= 20;
      else if (daysSince > 15) score -= 10;
    }
    return score.clamp(0, 100);
  }

  static double? _aumForIndex(int seed, Random rng) {
    final tier = seed % 5;
    switch (tier) {
      case 0:
        return null; // Unknown
      case 1:
        return (rng.nextInt(9) + 1) * 100000; // <10L
      case 2:
        return (rng.nextInt(40) + 10) * 100000; // 10-50L
      case 3:
        return (rng.nextInt(50) + 50) * 100000; // 50L-1Cr
      default:
        return (rng.nextInt(40) + 10) * 1000000; // 1Cr-5Cr
    }
  }

  static List<ActivityModel> _generateActivities({
    required String leadId,
    required int count,
    required String rmId,
    required String rmName,
    required DateTime createdAt,
    required Random rng,
  }) {
    final activities = <ActivityModel>[];
    final now = DateTime.now();
    final daySpan = now.difference(createdAt).inDays.clamp(1, 90);

    // System activity: lead created
    activities.add(ActivityModel(
      id: '${leadId}_ACT_000',
      leadId: leadId,
      type: ActivityType.system,
      dateTime: createdAt,
      notes: 'Lead created',
      loggedById: 'SYSTEM',
      loggedByName: 'System',
      isSystemGenerated: true,
      createdAt: createdAt,
    ));

    for (var j = 1; j <= count; j++) {
      final daysAgo = rng.nextInt(daySpan);
      final activityDate = now.subtract(Duration(days: daysAgo, hours: rng.nextInt(10) + 8));
      final type = ActivityType.values[rng.nextInt(4)]; // call, meeting, note, whatsapp

      activities.add(ActivityModel(
        id: '${leadId}_ACT_${j.toString().padLeft(3, '0')}',
        leadId: leadId,
        type: type,
        dateTime: activityDate,
        durationMinutes: type == ActivityType.call
            ? rng.nextInt(20) + 3
            : (type == ActivityType.meeting ? rng.nextInt(45) + 15 : null),
        notes: _activityNote(type, rng),
        outcome: type == ActivityType.call || type == ActivityType.meeting
            ? ActivityOutcome.values[rng.nextInt(ActivityOutcome.values.length)]
            : null,
        loggedById: rmId,
        loggedByName: rmName,
        createdAt: activityDate,
      ));
    }

    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return activities;
  }

  static String _activityNote(ActivityType type, Random rng) {
    final notes = {
      ActivityType.call: [
        'Discussed portfolio options', 'Introduced MF products',
        'Follow-up on previous meeting', 'Confirmed interest in PMS',
        'Left voicemail', 'Called to schedule meeting',
      ],
      ActivityType.meeting: [
        'Presented investment proposal', 'KYC document collection',
        'Product walkthrough session', 'Risk profiling discussion',
        'Portfolio review meeting', 'Family office discussion',
      ],
      ActivityType.note: [
        'High net worth individual, good potential', 'Prefers conservative investments',
        'Interested in tax-saving products', 'Decision maker confirmed',
        'Referred by existing HNI client', 'Needs time to decide',
      ],
      ActivityType.whatsApp: [
        'Shared product brochure', 'Sent meeting invite',
        'Shared market update', 'Confirmed appointment time',
      ],
    };
    final pool = notes[type] ?? ['Activity logged'];
    return pool[rng.nextInt(pool.length)];
  }
}
