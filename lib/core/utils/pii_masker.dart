/// DPDP-compliant PII masking utilities.
/// Shows only the minimum identifiable portion of each field.
class PiiMasker {
  PiiMasker._();

  /// +91 9876543210 → •••• •••• 3210
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 4) return '••••';
    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• $last4';
  }

  /// rajesh.mehta@gmail.com → r••••@gmail.com
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '••••@••••';
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return '••••@$domain';
    return '${local[0]}••••@$domain';
  }

  /// Rajesh Mehta → Rajesh M.
  static String maskName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return name;
    return '${parts.first} ${parts.last[0]}.';
  }

  /// ABCDE1234F → ••••••234F
  static String maskPan(String pan) {
    if (pan.length < 4) return '••••';
    return '••••••${pan.substring(pan.length - 4)}';
  }

  /// Generic: show last N chars, mask the rest
  static String maskGeneric(String value, {int showLast = 4}) {
    if (value.length <= showLast) return value;
    final masked = '•' * (value.length - showLast);
    return '$masked${value.substring(value.length - showLast)}';
  }

  /// Returns true if the current user should see unmasked PII for a given lead.
  /// Owning RM + admin/compliance see full data; others see masked.
  static bool canViewFull({
    required String currentUserId,
    required String? currentUserRole,
    required String leadOwnerId,
  }) {
    if (currentUserId == leadOwnerId) return true;
    if (currentUserRole == 'ADM' || currentUserRole == 'CMP') return true;
    return false;
  }
}
