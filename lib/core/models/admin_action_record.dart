enum AdminLeadAction { returnedToPool, keptDropped }

class AdminActionRecord {
  final String adminId;
  final String adminName;
  final AdminLeadAction action;
  final String remarks;
  final DateTime decidedAt;

  const AdminActionRecord({
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.remarks,
    required this.decidedAt,
  });
}
