/// Per-day mock data for the Day Snapshot widget. Production: an endpoint
/// like `/home/day-snapshot?date=YYYY-MM-DD` that aggregates activity log,
/// lead-create events, and stage-change events for the selected date and
/// the calling RM.
class DaySnapshot {
  final int callsLogged;
  final int meetingsLogged;
  final int emailsLogged;
  final int leadsCaptured;
  final int stageMoves;
  final List<String> stageMovesBreakdown; // human-readable bullets
  final int scheduledFollowUps; // future-only
  final int scheduledMeetings;  // future-only

  const DaySnapshot({
    this.callsLogged = 0,
    this.meetingsLogged = 0,
    this.emailsLogged = 0,
    this.leadsCaptured = 0,
    this.stageMoves = 0,
    this.stageMovesBreakdown = const [],
    this.scheduledFollowUps = 0,
    this.scheduledMeetings = 0,
  });

  int get activitiesLogged => callsLogged + meetingsLogged + emailsLogged;
  bool get isEmpty =>
      activitiesLogged == 0 &&
      leadsCaptured == 0 &&
      stageMoves == 0 &&
      scheduledFollowUps == 0 &&
      scheduledMeetings == 0;
}

class DaySnapshotData {
  DaySnapshotData._();

  /// Pick mock data based on date offset from today.
  static DaySnapshot forDate(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final picked = DateTime(date.year, date.month, date.day);
    final offset = picked.difference(today).inDays;

    switch (offset) {
      case -1:
        // Yesterday — completed retrospective
        return const DaySnapshot(
          callsLogged: 3,
          meetingsLogged: 1,
          emailsLogged: 2,
          leadsCaptured: 1,
          stageMoves: 2,
          stageMovesBreakdown: [
            '1 → contacted',
            '1 → ib_pending',
          ],
        );
      case 0:
        // Today
        return const DaySnapshot(
          callsLogged: 2,
          meetingsLogged: 1,
          emailsLogged: 1,
          leadsCaptured: 2,
          stageMoves: 3,
          stageMovesBreakdown: [
            '2 → contacted',
            '1 → ib_pending',
          ],
          scheduledFollowUps: 4,
          scheduledMeetings: 2,
        );
      case 1:
        // Tomorrow
        return const DaySnapshot(
          scheduledFollowUps: 5,
          scheduledMeetings: 1,
        );
      case 2:
        return const DaySnapshot(
          scheduledFollowUps: 2,
          scheduledMeetings: 0,
        );
      case 3:
        return const DaySnapshot(
          scheduledFollowUps: 1,
          scheduledMeetings: 1,
        );
      default:
        // Older days or further future — empty
        return const DaySnapshot();
    }
  }
}
