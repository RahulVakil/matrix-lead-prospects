import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/repositories/notification_repository.dart';

class NotificationsState extends Equatable {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? error;

  const NotificationsState({
    this.isLoading = true,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? error,
  }) =>
      NotificationsState(
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, notifications.length, unreadCount, error];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  final String userId;
  final NotificationRepository _repo = getIt<NotificationRepository>();

  NotificationsCubit({required this.userId}) : super(const NotificationsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await _repo.getForUser(userId);
      final unread = list.where((n) => !n.isRead).length;
      emit(state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    await load();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead(userId);
    await load();
  }
}
