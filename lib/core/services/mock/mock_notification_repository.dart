import 'dart:async';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _notifications = [];
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  MockNotificationRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(
        id: 'NTF001',
        type: NotificationType.followUpDue,
        title: 'Follow-up due',
        body: 'Rajesh Mehta callback scheduled in 30 minutes',
        deepLink: '/leads/LEAD0001',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'NTF002',
        type: NotificationType.leadAssigned,
        title: 'New lead assigned',
        body: '5 new leads assigned to you overnight from Campaign ABC',
        deepLink: '/leads',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'NTF003',
        type: NotificationType.systemInfo,
        title: 'Welcome to Matrix',
        body: 'Your Lead & Prospects workspace is ready',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }

  @override
  Stream<List<NotificationModel>> watchForUser(String userId) {
    Future.microtask(() => _controller.add(_listFor(userId)));
    return _controller.stream;
  }

  @override
  Future<List<NotificationModel>> getForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _listFor(userId);
  }

  @override
  Future<int> unreadCount(String userId) async {
    return _listFor(userId).where((n) => !n.isRead).length;
  }

  @override
  Future<void> markRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _emit();
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUserId == null ||
          _notifications[i].recipientUserId == userId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _emit();
  }

  @override
  Future<void> push(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _emit();
  }

  List<NotificationModel> _listFor(String userId) {
    return _notifications
        .where((n) => n.recipientUserId == null || n.recipientUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _emit() {
    _controller.add(List<NotificationModel>.from(_notifications));
  }
}
