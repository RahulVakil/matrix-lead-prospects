import '../enums/retention_status.dart';

/// Tracks DPDP retention lifecycle for a lead.
/// Leads inactive for 180+ days are auto-flagged for review.
class DataRetentionModel {
  final String leadId;
  final DateTime dataCreatedAt;
  final DateTime lastActivityAt;
  final int retentionDays;
  final RetentionStatus status;
  final DateTime? flaggedForReviewAt;
  final String? reviewedByUserId;
  final String? reviewDecision; // 'extend' | 'delete'

  const DataRetentionModel({
    required this.leadId,
    required this.dataCreatedAt,
    required this.lastActivityAt,
    this.retentionDays = 180,
    this.status = RetentionStatus.active,
    this.flaggedForReviewAt,
    this.reviewedByUserId,
    this.reviewDecision,
  });

  bool get isOverdue {
    final daysSinceActivity =
        DateTime.now().difference(lastActivityAt).inDays;
    return daysSinceActivity > retentionDays;
  }

  int get daysUntilExpiry {
    final elapsed = DateTime.now().difference(lastActivityAt).inDays;
    return (retentionDays - elapsed).clamp(-999, retentionDays);
  }

  String get expiryDisplay {
    final d = daysUntilExpiry;
    if (d < 0) return '${d.abs()} days overdue';
    if (d == 0) return 'Expires today';
    return '$d days remaining';
  }

  DataRetentionModel extend() {
    return DataRetentionModel(
      leadId: leadId,
      dataCreatedAt: dataCreatedAt,
      lastActivityAt: DateTime.now(),
      retentionDays: retentionDays,
      status: RetentionStatus.retentionExtended,
      reviewedByUserId: reviewedByUserId,
      reviewDecision: 'extend',
    );
  }

  DataRetentionModel markForDeletion({required String byUserId}) {
    return DataRetentionModel(
      leadId: leadId,
      dataCreatedAt: dataCreatedAt,
      lastActivityAt: lastActivityAt,
      retentionDays: retentionDays,
      status: RetentionStatus.markedForDeletion,
      flaggedForReviewAt: flaggedForReviewAt,
      reviewedByUserId: byUserId,
      reviewDecision: 'delete',
    );
  }
}
