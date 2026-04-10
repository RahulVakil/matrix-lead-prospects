import '../../enums/activity_type.dart';
import '../../models/activity_model.dart';
import '../../repositories/activity_repository.dart';

class MockActivityRepository implements ActivityRepository {
  final Map<String, List<ActivityModel>> _activitiesCache = {};

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

  void seedActivities(String leadId, List<ActivityModel> activities) {
    _activitiesCache[leadId] = activities;
  }
}
