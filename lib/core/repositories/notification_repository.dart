import '../models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> watchForUser(String userId);
  Future<List<NotificationModel>> getForUser(String userId);
  Future<int> unreadCount(String userId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String userId);
  Future<void> push(NotificationModel notification);
}
