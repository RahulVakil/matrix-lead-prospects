import '../enums/activity_type.dart';

class ActivityModel {
  final String id;
  final String leadId;
  final ActivityType type;
  final DateTime dateTime;
  final int? durationMinutes;
  final String? notes;
  final ActivityOutcome? outcome;
  final String loggedById;
  final String loggedByName;
  final bool isSystemGenerated;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.leadId,
    required this.type,
    required this.dateTime,
    this.durationMinutes,
    this.notes,
    this.outcome,
    required this.loggedById,
    required this.loggedByName,
    this.isSystemGenerated = false,
    required this.createdAt,
  });

  String get durationDisplay {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 60) return '${durationMinutes}min';
    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String get timeDisplay {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (activityDate == today) return 'Today';
    if (activityDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${dateTime.day} ${_monthName(dateTime.month)}';
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
