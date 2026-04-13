import '../enums/audit_action.dart';

/// One entry in the DPDP audit trail — records who accessed what PII, when.
class AuditLogEntry {
  final String id;
  final String userId;
  final String userName;
  final AuditAction action;
  final String entityType; // 'lead', 'client', 'ib_lead'
  final String entityId;
  final String? fieldAccessed; // e.g. 'phone', 'email', 'pan'
  final DateTime timestamp;
  final String? details;

  const AuditLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.fieldAccessed,
    required this.timestamp,
    this.details,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }

  String get summaryDisplay {
    final field = fieldAccessed != null ? ' ($fieldAccessed)' : '';
    return '${action.label}$field';
  }
}
