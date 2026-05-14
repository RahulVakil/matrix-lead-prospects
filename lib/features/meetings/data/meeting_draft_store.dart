import 'package:flutter/foundation.dart';
import '../../../core/enums/activity_type.dart';
import '../../../core/enums/next_action_type.dart';

/// Saved-but-unsubmitted state of a meeting log.
///
/// Mirrors the inputs on `ActivityQuickLogSheet` (lead-module activity log)
/// so the meeting log surface is field-by-field identical. Add a draft on
/// "Save as draft", remove on a successful "Log meeting".
class MeetingDraft {
  final ActivityOutcome? outcome;
  final int? durationMinutes;
  final bool meetingIsOnline;
  final String meetingLink;
  final String meetingLocation;
  final String notes;
  final NextActionType? nextActionType;
  final DateTime? nextActionDate;
  final DateTime updatedAt;

  const MeetingDraft({
    this.outcome,
    this.durationMinutes,
    this.meetingIsOnline = true,
    this.meetingLink = '',
    this.meetingLocation = '',
    this.notes = '',
    this.nextActionType,
    this.nextActionDate,
    required this.updatedAt,
  });
}

/// In-memory draft store. Production: persist to local storage so drafts
/// survive app restarts. Uses [ChangeNotifier] so the Meetings section on
/// home can re-render the "Draft" pill the moment a draft is saved or
/// cleared, without needing a manual refresh.
class MeetingDraftStore extends ChangeNotifier {
  MeetingDraftStore._();
  static final MeetingDraftStore instance = MeetingDraftStore._();

  final Map<String, MeetingDraft> _drafts = {};

  bool hasDraft(String meetingId) => _drafts.containsKey(meetingId);
  MeetingDraft? getDraft(String meetingId) => _drafts[meetingId];

  void save(String meetingId, MeetingDraft draft) {
    _drafts[meetingId] = draft;
    notifyListeners();
  }

  void clear(String meetingId) {
    if (_drafts.remove(meetingId) != null) {
      notifyListeners();
    }
  }
}
