/// Timeframe filter for the Leadership Dashboard. Drives the chip row at
/// the top of the page and the cubit's `since` cutoff used to slice leads
/// (createdAt OR lastContactedAt within window) and roll up the activity
/// counter strip. `inception` returns a null cutoff so all-time data
/// (current dashboard behaviour) is preserved as the default.
enum TimeframeFilter {
  today,
  week,
  month,
  inception;

  String get label {
    switch (this) {
      case TimeframeFilter.today:
        return 'Today';
      case TimeframeFilter.week:
        return '1 Week';
      case TimeframeFilter.month:
        return '1 Month';
      case TimeframeFilter.inception:
        return 'Inception';
    }
  }

  /// Cutoff datetime — leads/activities at or after this point fall in
  /// the window. Inception returns null (= no filter).
  DateTime? get since {
    final now = DateTime.now();
    switch (this) {
      case TimeframeFilter.today:
        return DateTime(now.year, now.month, now.day);
      case TimeframeFilter.week:
        return now.subtract(const Duration(days: 7));
      case TimeframeFilter.month:
        return now.subtract(const Duration(days: 30));
      case TimeframeFilter.inception:
        return null;
    }
  }

  /// Activity-section header for the chosen filter.
  String get activityHeading {
    switch (this) {
      case TimeframeFilter.today:
        return 'ACTIVITY – TODAY';
      case TimeframeFilter.week:
        return 'ACTIVITY – LAST 7 DAYS';
      case TimeframeFilter.month:
        return 'ACTIVITY – LAST 30 DAYS';
      case TimeframeFilter.inception:
        return 'ACTIVITY – INCEPTION';
    }
  }
}
