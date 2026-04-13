import '../enums/consent_type.dart';

/// One consent grant (or revocation) per lead per consent type.
class ConsentRecord {
  final String id;
  final String leadId;
  final DataConsentType consentType;
  final DateTime grantedAt;
  final String grantedByUserId;
  final String grantedByUserName;
  final String purposeStatement;
  final bool isActive;
  final DateTime? revokedAt;
  final String? revokedByUserId;

  const ConsentRecord({
    required this.id,
    required this.leadId,
    required this.consentType,
    required this.grantedAt,
    required this.grantedByUserId,
    required this.grantedByUserName,
    required this.purposeStatement,
    this.isActive = true,
    this.revokedAt,
    this.revokedByUserId,
  });

  ConsentRecord revoke({required String byUserId}) {
    return ConsentRecord(
      id: id,
      leadId: leadId,
      consentType: consentType,
      grantedAt: grantedAt,
      grantedByUserId: grantedByUserId,
      grantedByUserName: grantedByUserName,
      purposeStatement: purposeStatement,
      isActive: false,
      revokedAt: DateTime.now(),
      revokedByUserId: byUserId,
    );
  }

  String get statusDisplay => isActive ? 'Active' : 'Revoked';
}
