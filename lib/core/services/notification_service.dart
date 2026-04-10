import '../models/notification_model.dart';

/// Production-grade notification service abstraction.
/// Phase 1: backed by [InAppNotificationService] which writes to the
/// in-app inbox via [NotificationRepository] and shows due-now banners.
/// Phase 5: swap in [FcmNotificationService] (firebase_messaging) without
/// touching call sites — same interface, same method signatures.
abstract class NotificationService {
  /// Initialise the underlying transport. Idempotent.
  Future<void> init();

  /// Request OS-level permission. No-op on web.
  Future<bool> requestPermission();

  /// Subscribe the current user to a topic (e.g. "branch-head-mumbai",
  /// "ib-team", "rm-rm001"). Topic-based fanout maps cleanly to FCM later.
  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  /// Push a notification. In Phase 1 this lands in the in-app inbox; in
  /// production it travels via FCM.
  Future<void> push({
    required String topic,
    required NotificationModel notification,
  });

  /// Stream of foreground messages received while the app is open.
  Stream<NotificationModel> get onMessage;

  /// Token used by the server to address this device. Null on web/mock.
  Future<String?> getToken();
}
