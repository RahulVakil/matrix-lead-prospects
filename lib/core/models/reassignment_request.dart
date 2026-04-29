/// Re-assignment request workflow. Created when an RM hits the Coverage
/// "existing client" warning during Add Lead and clicks "Request reassignment".
/// Surfaces in Manage Pool's REASSIGNMENT tab; Admin / MIS approves or
/// rejects with a reason. Both source RM (capturing) and target RM
/// (current client owner) are notified on decision.
enum ReassignmentStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String label;
  const ReassignmentStatus(this.label);
}

class ReassignmentRequest {
  final String id;
  /// The matched ClientMaster record's ID (or empty if pre-creation).
  final String matchedClientId;
  final String matchedClientName;
  /// The RM trying to capture the lead (will receive ownership on approve).
  final String sourceRmId;
  final String sourceRmName;
  /// The RM currently owning the matched client. Nullable since coverage may
  /// not always know — e.g. company-master matches without an RM linkage.
  final String? targetRmId;
  final String? targetRmName;
  /// Free-text reason supplied by the requester (auto-derived if blank).
  final String reason;
  final ReassignmentStatus status;
  /// Reason supplied by Admin when rejecting; null otherwise.
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedByAdminId;
  final String? decidedByAdminName;

  const ReassignmentRequest({
    required this.id,
    required this.matchedClientId,
    required this.matchedClientName,
    required this.sourceRmId,
    required this.sourceRmName,
    this.targetRmId,
    this.targetRmName,
    required this.reason,
    this.status = ReassignmentStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.decidedAt,
    this.decidedByAdminId,
    this.decidedByAdminName,
  });

  ReassignmentRequest copyWith({
    String? id,
    String? matchedClientId,
    String? matchedClientName,
    String? sourceRmId,
    String? sourceRmName,
    String? targetRmId,
    String? targetRmName,
    String? reason,
    ReassignmentStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? decidedAt,
    String? decidedByAdminId,
    String? decidedByAdminName,
  }) {
    return ReassignmentRequest(
      id: id ?? this.id,
      matchedClientId: matchedClientId ?? this.matchedClientId,
      matchedClientName: matchedClientName ?? this.matchedClientName,
      sourceRmId: sourceRmId ?? this.sourceRmId,
      sourceRmName: sourceRmName ?? this.sourceRmName,
      targetRmId: targetRmId ?? this.targetRmId,
      targetRmName: targetRmName ?? this.targetRmName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedByAdminId: decidedByAdminId ?? this.decidedByAdminId,
      decidedByAdminName: decidedByAdminName ?? this.decidedByAdminName,
    );
  }
}
