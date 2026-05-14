import '../../enums/activity_type.dart';
import '../../models/activity_model.dart';
import '../../repositories/activity_repository.dart';

class MockActivityRepository implements ActivityRepository {
  final Map<String, List<ActivityModel>> _activitiesCache = {};

  MockActivityRepository() {
    _seedDemoActivities();
  }

  /// Plants a rich 9-day timeline on LEAD_D (Rohit Agarwal · owned by
  /// Priya Sharma / RM001) so the TL "View call logs / View meetings /
  /// View notes" sheets render meaningful content out of the box.
  void _seedDemoActivities() {
    const leadId = 'LEAD_D';
    const rmId = 'R-101';
    const rmName = 'Aanya Khanna';
    final now = DateTime.now();
    DateTime at(int daysAgo, int hour, int minute) {
      final d = now.subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }
    var seq = 0;
    String nextId() => 'SEED_${leadId}_${++seq}';

    final entries = <ActivityModel>[
      // ── Calls ───────────────────────────────────────────────────────
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.call,
        dateTime: at(1, 10, 42), durationMinutes: 6,
        outcome: ActivityOutcome.connected,
        notes: 'Walked through the PMS proposal v2. Client okay with ₹50L '
            'ticket but wants exit-load comparison vs MF route. Sending '
            'one-pager today.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(1, 10, 42),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.call,
        dateTime: at(2, 16, 15),
        outcome: ActivityOutcome.noAnswer,
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(2, 16, 15),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.call,
        dateTime: at(5, 11, 20), durationMinutes: 12,
        outcome: ActivityOutcome.interested,
        notes: 'Asked allocation breakup. Currently 70% MF, 20% direct '
            'equity, 10% FD. Open to PMS — wants 12-15% target return '
            'discussion.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(5, 11, 20),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.call,
        dateTime: at(7, 18, 50), durationMinutes: 2,
        outcome: ActivityOutcome.voicemail,
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(7, 18, 50),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.call,
        dateTime: at(9, 9, 35), durationMinutes: 4,
        outcome: ActivityOutcome.followUp,
        notes: 'Intro call. Referred by Mr. Joshi (existing client). Will '
            'share product deck on email and follow up Wed.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(9, 9, 35),
      ),
      // ── Meetings ────────────────────────────────────────────────────
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.meeting,
        dateTime: at(0, 15, 0), durationMinutes: 45,
        outcome: ActivityOutcome.interested,
        notes: 'Video call with Ajay + his CA Mehul. Walked through SOA + '
            'tax implications. CA fine with structure. Next: send '
            'IB-onboarding form.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(0, 15, 0),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.meeting,
        dateTime: at(6, 11, 0), durationMinutes: 60,
        outcome: ActivityOutcome.connected,
        notes: 'Branch meet at Worli office. Met spouse too. Risk profile '
            'leans moderate. Comfortable with 3-yr horizon. Shared PMS '
            'deck physically.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(6, 11, 0),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.meeting,
        dateTime: at(8, 16, 0), durationMinutes: 30,
        outcome: ActivityOutcome.followUp,
        notes: "First in-person at client's office (BKC). Brief intro, "
            'took KYC docs, will revert with proposal.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(8, 16, 0),
      ),
      // ── Notes ───────────────────────────────────────────────────────
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.note,
        dateTime: at(0, 18, 30),
        notes: 'Family context — wife Priya is on board, brother Karan is '
            'also a potential lead (runs a textile export biz, ~₹12 Cr '
            "turnover). Will introduce post-Ajay's onboarding.",
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(0, 18, 30),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.note,
        dateTime: at(5, 14, 10),
        notes: 'Risk appetite confirmed: moderate-aggressive. Net worth '
            "~₹4.5 Cr (3 properties + ₹1.2 Cr liquid). Doesn't want any "
            'debt-heavy product. PMS / equity-MF basket only.',
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(5, 14, 10),
      ),
      ActivityModel(
        id: nextId(), leadId: leadId, type: ActivityType.note,
        dateTime: at(9, 11, 0),
        notes: 'Referred by Mr. Anil Joshi (client ID: C-44218). Anil '
            'specifically asked us not to assign this to the call centre '
            "— wants 'his RM' (Aanya) to handle directly.",
        loggedById: rmId, loggedByName: rmName,
        createdAt: at(9, 11, 0),
      ),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    _activitiesCache[leadId] = entries;
  }

  @override
  Future<List<ActivityModel>> getActivitiesForLead(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _activitiesCache[leadId] ?? [];
  }

  @override
  Future<ActivityModel> logActivity({
    required String leadId,
    required ActivityType type,
    required DateTime dateTime,
    int? durationMinutes,
    String? notes,
    ActivityOutcome? outcome,
    required String loggedById,
    required String loggedByName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final activity = ActivityModel(
      id: '${leadId}_ACT_${DateTime.now().millisecondsSinceEpoch}',
      leadId: leadId,
      type: type,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      notes: notes,
      outcome: outcome,
      loggedById: loggedById,
      loggedByName: loggedByName,
      createdAt: DateTime.now(),
    );

    _activitiesCache.putIfAbsent(leadId, () => []);
    _activitiesCache[leadId]!.insert(0, activity);

    return activity;
  }

  @override
  Future<ActivityModel> updateActivity({
    required String activityId,
    required String leadId,
    DateTime? dateTime,
    int? durationMinutes,
    String? notes,
    ActivityOutcome? outcome,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final list = _activitiesCache[leadId] ?? [];
    final idx = list.indexWhere((a) => a.id == activityId);
    if (idx == -1) {
      throw StateError('Activity $activityId not found for lead $leadId');
    }
    final updated = list[idx].copyWith(
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      notes: notes,
      outcome: outcome,
    );
    list[idx] = updated;
    return updated;
  }

  void seedActivities(String leadId, List<ActivityModel> activities) {
    _activitiesCache[leadId] = activities;
  }
}
