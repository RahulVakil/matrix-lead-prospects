import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/repositories/notification_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/compass_badge.dart';

class AppTopBar extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const AppTopBar({
    super.key,
    required this.user,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 18,
        right: 18,
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MATRIX',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textOnDark,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.name} · ${user.role.code}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<int>(
            future: getIt<NotificationRepository>().unreadCount(user.id),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
                onPressed: () => context.push('/notifications'),
                icon: CompassBadge(
                  count: count,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textOnDark,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.avatarBackground,
              child: Text(
                user.initials,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
