import '../models/activity_model.dart';
import '../enums/activity_type.dart';

abstract class ActivityRepository {
  Future<List<ActivityModel>> getActivitiesForLead(String leadId);

  Future<ActivityModel> logActivity({
    required String leadId,
    required ActivityType type,
    required DateTime dateTime,
    int? durationMinutes,
    String? notes,
    ActivityOutcome? outcome,
    required String loggedById,
    required String loggedByName,
  });
}
