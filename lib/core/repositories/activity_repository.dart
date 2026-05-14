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

  /// Update fields on an existing activity record. Used to transition a
  /// scheduled meeting (`outcome = followUp`) to either `completed` (with
  /// notes / duration) or `cancelled` without creating a duplicate entry.
  /// Returns the updated record.
  Future<ActivityModel> updateActivity({
    required String activityId,
    required String leadId,
    DateTime? dateTime,
    int? durationMinutes,
    String? notes,
    ActivityOutcome? outcome,
  });
}
