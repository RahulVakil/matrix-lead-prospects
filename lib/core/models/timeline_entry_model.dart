import '../enums/update_type.dart';

/// View-model representing a single row on the merged Lead Detail timeline.
/// Built at read time from underlying activities, status updates, stage
/// changes, deal edits, and IB-lead-created events.
class TimelineEntryModel {
  final String id;
  final String leadId;
  final TimelineEntryType type;
  final DateTime dateTime;
  final String title;
  final String? subtitle;
  final String? notes;
  final String? authorName;
  final String? relatedEntityId; // e.g. ibLeadId, activityId

  const TimelineEntryModel({
    required this.id,
    required this.leadId,
    required this.type,
    required this.dateTime,
    required this.title,
    this.subtitle,
    this.notes,
    this.authorName,
    this.relatedEntityId,
  });

  String get timeDisplay {
    final hh = dateTime.hour;
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final period = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh > 12 ? hh - 12 : (hh == 0 ? 12 : hh);
    return '$h12:$mm $period';
  }

  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }
}
