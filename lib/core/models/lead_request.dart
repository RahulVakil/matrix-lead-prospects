/// Request submitted by an RM (or TL) for leads from the shared pool.
/// Workflow: RM submits a pending request → Admin/MIS sees it on Manage
/// Pool's Requests tab and assigns leads via the existing leads-picker
/// sheet → request is marked Fulfilled with the assigned lead IDs and
/// timestamp. Both RM and TL are notified at each step. The audit trail
/// is surfaced on the Get Lead screen.
enum LeadRequestStatus {
  pending('Pending'),
  fulfilled('Fulfilled'),
  cancelled('Cancelled');

  final String label;
  const LeadRequestStatus(this.label);
}

class LeadRequest {
  final String id;
  final String rmId;
  final String rmName;
  /// Captured at request-creation time so notifications + team-scoped
  /// audit trail can be retrieved without re-deriving from the user table.
  final String? teamLeadId;
  final String? teamLeadName;
  final String? teamId;
  final int requestedCount;
  final LeadRequestStatus status;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final List<String> assignedLeadIds;
  final String? fulfilledByAdminId;
  final String? fulfilledByAdminName;

  const LeadRequest({
    required this.id,
    required this.rmId,
    required this.rmName,
    this.teamLeadId,
    this.teamLeadName,
    this.teamId,
    required this.requestedCount,
    this.status = LeadRequestStatus.pending,
    required this.createdAt,
    this.fulfilledAt,
    this.assignedLeadIds = const [],
    this.fulfilledByAdminId,
    this.fulfilledByAdminName,
  });

  LeadRequest copyWith({
    String? id,
    String? rmId,
    String? rmName,
    String? teamLeadId,
    String? teamLeadName,
    String? teamId,
    int? requestedCount,
    LeadRequestStatus? status,
    DateTime? createdAt,
    DateTime? fulfilledAt,
    List<String>? assignedLeadIds,
    String? fulfilledByAdminId,
    String? fulfilledByAdminName,
  }) {
    return LeadRequest(
      id: id ?? this.id,
      rmId: rmId ?? this.rmId,
      rmName: rmName ?? this.rmName,
      teamLeadId: teamLeadId ?? this.teamLeadId,
      teamLeadName: teamLeadName ?? this.teamLeadName,
      teamId: teamId ?? this.teamId,
      requestedCount: requestedCount ?? this.requestedCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      assignedLeadIds: assignedLeadIds ?? this.assignedLeadIds,
      fulfilledByAdminId: fulfilledByAdminId ?? this.fulfilledByAdminId,
      fulfilledByAdminName: fulfilledByAdminName ?? this.fulfilledByAdminName,
    );
  }
}
