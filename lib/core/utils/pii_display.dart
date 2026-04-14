import '../enums/consent_type.dart';

/// DPDP-compliant PII rendering helpers for dev + production surfaces.
/// Use these when rendering any user's phone / email / name on RM / Admin-facing
/// screens. Consent gating lives in [shouldShowUnmasked].
class PiiDisplay {
  PiiDisplay._();

  /// Phone: last 4 digits only — "XXXXXX3210". Strips non-digits first.
  /// Returns the original if the digit count isn't >=4.
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return phone;
    final last4 = digits.substring(digits.length - 4);
    return 'XXXXXX$last4';
  }

  /// Email: first character of local part + example.com domain.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return email;
    final first = email.substring(0, 1);
    return '$first***@example.com';
  }

  /// Name → first name + last-name initial (e.g. "Rahul V.").
  static String maskName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return fullName;
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  /// Consent-gated predicate. Full PII is only shown when consent is granted
  /// or partially granted. Pending / revoked → masked.
  static bool shouldShowUnmasked(ConsentStatus status) {
    return status == ConsentStatus.granted ||
        status == ConsentStatus.partial;
  }

  /// Convenience: returns [value] or its masked form based on consent.
  static String phoneFor(String phone, ConsentStatus status) =>
      shouldShowUnmasked(status) ? phone : maskPhone(phone);

  static String emailFor(String email, ConsentStatus status) =>
      shouldShowUnmasked(status) ? email : maskEmail(email);

  static String nameFor(String name, ConsentStatus status) =>
      shouldShowUnmasked(status) ? name : maskName(name);
}
