import 'dart:async';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import 'notification_service.dart';

/// Phase 1 implementation of [NotificationService] that fans out to the
/// in-app [NotificationRepository] inbox. The interface is FCM-shaped so a
/// later phase can replace this with [FcmNotificationService].
class InAppNotificationService implements NotificationService {
  final NotificationRepository _repository;
  final _messageController = StreamController<NotificationModel>.broadcast();
  final Set<String> _topics = {};
  bool _initialised = false;

  InAppNotificationService(this._repository);

  @override
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> subscribeToTopic(String topic) async {
    _topics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _topics.remove(topic);
  }

  @override
  Future<void> push({
    required String topic,
    required NotificationModel notification,
  }) async {
    await _repository.push(notification);
    _messageController.add(notification);
  }

  @override
  Stream<NotificationModel> get onMessage => _messageController.stream;

  @override
  Future<String?> getToken() async => null;
}
