/// Meeting record displayed on the home Meetings section, the Meetings
/// list screen, and the Meeting Detail screen.
/// Production: sourced from MeetingsCubit / Outlook integration.
class MeetingModel {
  final String id;
  final String date;          // "06"
  final String month;         // "May"
  final String name;          // "Aanya Khanna"
  final String location;      // "Andheri" or "Microsoft Teams"
  final String time;          // "12:30 pm"
  final bool isVideo;         // true → Join button, false → Start button
  final bool isHighPriority;
  final bool canStart;
  final bool isUpcoming;      // matches production's MeetingEntity.isUpcoming
  final String? leadId;
  final String? agenda;

  const MeetingModel({
    required this.id,
    required this.date,
    required this.month,
    required this.name,
    required this.location,
    required this.time,
    this.isVideo = false,
    this.isHighPriority = false,
    this.canStart = true,
    this.isUpcoming = true,
    this.leadId,
    this.agenda,
  });
}
