/// Indian Rupee currency helpers — lakh/crore grouping and number-to-words.
class IndianCurrencyFormatter {
  IndianCurrencyFormatter._();

  /// Formats a number with Indian digit grouping: 12,34,56,789
  static String format(num value) {
    final whole = value.truncate();
    final s = whole.abs().toString();
    if (s.length <= 3) return value.isNegative ? '-$s' : s;

    final last3 = s.substring(s.length - 3);
    final head = _reverseGroup(s);
    final out = head.isEmpty ? last3 : '$head,$last3';
    return value.isNegative ? '-$out' : out;
  }

  static String _reverseGroup(String s) {
    if (s.length <= 3) return '';
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return parts.join(',');
  }

  /// Pretty short form: ₹1.5 Cr / ₹45 L / ₹12,345
  static String shortForm(num value) {
    if (value >= 10000000) {
      final cr = value / 10000000;
      return '₹${cr.toStringAsFixed(cr >= 10 ? 1 : 2)} Cr';
    }
    if (value >= 100000) {
      final l = value / 100000;
      return '₹${l.toStringAsFixed(l >= 10 ? 1 : 2)} L';
    }
    return '₹${format(value)}';
  }

  /// Converts a numeric amount into a words helper line, e.g.:
  /// 5_00_00_000 → "Five Crore Rupees"
  static String toWords(num value) {
    if (value == 0) return '';
    final n = value.truncate();
    if (n >= 10000000) {
      final cr = n / 10000000;
      return '${_pretty(cr)} Crore';
    }
    if (n >= 100000) {
      final l = n / 100000;
      return '${_pretty(l)} Lakh';
    }
    if (n >= 1000) {
      final k = n / 1000;
      return '${_pretty(k)} Thousand';
    }
    return '$n';
  }

  static String _pretty(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
