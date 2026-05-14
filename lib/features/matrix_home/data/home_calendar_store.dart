import 'package:flutter/foundation.dart';

/// Selected-date state shared across home widgets (calendar strip,
/// Meetings section, Day Snapshot, Leads at a glance). All listeners
/// rebuild when the user picks a different date in the strip.
class HomeCalendarStore extends ChangeNotifier {
  HomeCalendarStore._() : _selectedDate = _truncateToDay(DateTime.now());
  static final HomeCalendarStore instance = HomeCalendarStore._();

  DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  bool get isToday => _isSameDay(_selectedDate, DateTime.now());
  bool get isPast => _selectedDate.isBefore(_truncateToDay(DateTime.now()));
  bool get isFuture => _selectedDate.isAfter(_truncateToDay(DateTime.now()));

  void select(DateTime date) {
    final d = _truncateToDay(date);
    if (_isSameDay(d, _selectedDate)) return;
    _selectedDate = d;
    notifyListeners();
  }

  static DateTime _truncateToDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
