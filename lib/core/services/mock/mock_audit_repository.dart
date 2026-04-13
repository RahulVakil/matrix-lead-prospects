import '../../enums/audit_action.dart';
import '../../models/audit_log_entry.dart';
import '../../repositories/audit_repository.dart';

class MockAuditRepository implements AuditRepository {
  final List<AuditLogEntry> _entries = [];

  MockAuditRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _entries.addAll([
      AuditLogEntry(
        id: 'AUD001',
        userId: 'RM001',
        userName: 'Priya Sharma',
        action: AuditAction.viewCoverage,
        entityType: 'lead',
        entityId: 'LEAD0001',
        timestamp: now.subtract(const Duration(hours: 2)),
        details: 'Searched coverage for Rajesh Mehta',
      ),
      AuditLogEntry(
        id: 'AUD002',
        userId: 'RM001',
        userName: 'Priya Sharma',
        action: AuditAction.viewPII,
        entityType: 'lead',
        entityId: 'LEAD0001',
        fieldAccessed: 'phone',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  @override
  Future<void> log({
    required String userId,
    required String userName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    String? fieldAccessed,
    String? details,
  }) async {
    _entries.insert(
      0,
      AuditLogEntry(
        id: 'AUD_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        fieldAccessed: fieldAccessed,
        timestamp: DateTime.now(),
        details: details,
      ),
    );
  }

  @override
  Future<List<AuditLogEntry>> getForEntity(
    String entityType,
    String entityId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _entries
        .where((e) => e.entityType == entityType && e.entityId == entityId)
        .toList();
  }

  @override
  Future<List<AuditLogEntry>> getForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _entries.where((e) => e.userId == userId).toList();
  }
}
