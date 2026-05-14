import '../domain/meeting_model.dart';

/// Static mock meetings. Production: a MeetingsCubit + repository.
class MockMeetings {
  MockMeetings._();

  static const List<MeetingModel> all = [
    // ── Upcoming ────────────────────────────────────────────────────
    MeetingModel(
      id: 'M-001',
      date: '06',
      month: 'May',
      name: 'Aanya Khanna',
      location: 'Andheri',
      time: '12:30 pm',
      isVideo: false,
      isHighPriority: true,
      canStart: true,
      isUpcoming: true,
      leadId: 'L-1042',
      agenda: 'Discuss PMS allocation. Aanya signalled interest in equity-heavy '
          'tilt last call. Bring SIP top-up sheet.',
    ),
    MeetingModel(
      id: 'M-002',
      date: '06',
      month: 'May',
      name: 'Vikram Holdings — Quarterly review',
      location: 'Microsoft Teams',
      time: '04:00 pm',
      isVideo: true,
      isHighPriority: false,
      canStart: true,
      isUpcoming: true,
      leadId: 'L-1037',
      agenda: 'Q3 portfolio review. CFO will join. Cover IB pipeline + family '
          'office structure.',
    ),
    MeetingModel(
      id: 'M-003',
      date: '08',
      month: 'May',
      name: 'Asha Krishnan',
      location: 'JM Financial, BKC',
      time: '11:00 am',
      isVideo: false,
      isHighPriority: false,
      canStart: false,
      isUpcoming: true,
      leadId: 'L-1062',
      agenda: 'Onboarding kickoff — KYC + product walkthrough.',
    ),

    // ── Past ────────────────────────────────────────────────────────
    MeetingModel(
      id: 'M-090',
      date: '02',
      month: 'May',
      name: 'Patel Family Office',
      location: 'Ahmedabad branch',
      time: '03:30 pm',
      isVideo: false,
      isHighPriority: true,
      canStart: false,
      isUpcoming: false,
      leadId: 'L-1071',
      agenda: 'Family-group structuring discussion.',
    ),
    MeetingModel(
      id: 'M-088',
      date: '01',
      month: 'May',
      name: 'Sandeep Mehra',
      location: 'Zoom',
      time: '05:00 pm',
      isVideo: true,
      isHighPriority: false,
      canStart: false,
      isUpcoming: false,
      leadId: 'L-1051',
      agenda: 'Equity portfolio review — Q4 outlook.',
    ),
  ];

  static List<MeetingModel> upcoming() =>
      all.where((m) => m.isUpcoming).toList();
  static List<MeetingModel> past() =>
      all.where((m) => !m.isUpcoming).toList();

  static MeetingModel? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
