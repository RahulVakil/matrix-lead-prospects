import '../enums/audit_action.dart';
import '../models/audit_log_entry.dart';

abstract class AuditRepository {
  /// Log a PII access event.
  Future<void> log({
    required String userId,
    required String userName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    String? fieldAccessed,
    String? details,
  });

  /// Get audit trail for a specific entity (lead, client, etc.).
  Future<List<AuditLogEntry>> getForEntity(String entityType, String entityId);

  /// Get all audit entries by a specific user (for compliance review).
  Future<List<AuditLogEntry>> getForUser(String userId);
}
