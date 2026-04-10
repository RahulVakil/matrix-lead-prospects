import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NotificationType {
  ibLeadSubmitted('IB Lead Submitted', Icons.business_center, AppColors.navyPrimary),
  ibLeadApproved('IB Lead Approved', Icons.check_circle, AppColors.successGreen),
  ibLeadSentBack('IB Lead Returned', Icons.replay, AppColors.warmAmber),
  ibLeadForwarded('IB Lead Forwarded', Icons.send, AppColors.tealAccent),
  leadAssigned('New Lead Assigned', Icons.person_add, AppColors.coldBlue),
  followUpDue('Follow-up Due', Icons.alarm, AppColors.warmAmber),
  coverageAlert('Coverage Alert', Icons.shield_outlined, AppColors.errorRed),
  systemInfo('System', Icons.info_outline, AppColors.textSecondary);

  final String label;
  final IconData icon;
  final Color color;

  const NotificationType(this.label, this.icon, this.color);
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? deepLink; // route path, e.g. /ib-leads/IBL0001
  final DateTime createdAt;
  final bool isRead;
  final String? recipientUserId;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.deepLink,
    required this.createdAt,
    this.isRead = false,
    this.recipientUserId,
  });

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      deepLink: deepLink,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      recipientUserId: recipientUserId,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}';
  }
}
