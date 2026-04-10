import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => NotificationsCubit(userId: user.id)..load(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surfaceTertiary,
            appBar: CompassAppBar(
              title: 'Notifications',
              actions: [
                if (state.unreadCount > 0)
                  TextButton(
                    onPressed: () => context.read<NotificationsCubit>().markAllRead(),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: AppColors.textOnDark),
                    ),
                  ),
              ],
            ),
            body: state.isLoading
                ? const CompassLoader()
                : state.notifications.isEmpty
                    ? const CompassEmptyState(
                        icon: Icons.notifications_none,
                        title: 'No notifications',
                        subtitle: "We'll let you know when something needs your attention",
                      )
                    : _buildList(context, state.notifications),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<NotificationModel> items) {
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];
    final now = DateTime.now();
    final t0 = DateTime(now.year, now.month, now.day);
    final y0 = t0.subtract(const Duration(days: 1));
    for (final n in items) {
      if (n.createdAt.isAfter(t0)) {
        today.add(n);
      } else if (n.createdAt.isAfter(y0)) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        if (today.isNotEmpty) _section(context, 'TODAY', today),
        if (yesterday.isNotEmpty) _section(context, 'YESTERDAY', yesterday),
        if (earlier.isNotEmpty) _section(context, 'EARLIER', earlier),
      ],
    );
  }

  Widget _section(BuildContext context, String label, List<NotificationModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2),
          ),
        ),
        ...items.map((n) => _row(context, n)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _row(BuildContext context, NotificationModel n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CompassCard(
        onTap: () async {
          if (!n.isRead) {
            await context.read<NotificationsCubit>().markRead(n.id);
          }
          if (n.deepLink != null && context.mounted) {
            context.push(n.deepLink!);
          }
        },
        color: n.isRead ? AppColors.surfacePrimary : AppColors.surfaceTertiary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: n.type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(n.type.icon, size: 18, color: n.type.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(n.timeAgo, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.body, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.navyPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
