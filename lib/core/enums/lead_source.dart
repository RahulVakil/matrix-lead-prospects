enum LeadSource {
  selfGenerated('Self-generated', 'SRC_SLF', 20),
  procured('Procured', 'SRC_PRO', 15),
  referral('Referral', 'SRC_REF', 30),
  ifa('IFA Partner', 'SRC_IFA', 25),
  seminar('Seminar', 'SRC_SEM', 20),
  event('Event', 'SRC_EVT', 18),
  coldCall('Cold Call', 'SRC_CLD', 5),
  walkIn('Walk-in', 'SRC_WLK', 10),
  campaign('Campaign', 'SRC_CAM', 15),
  digital('Digital', 'SRC_DIG', 12);

  final String label;
  final String code;
  final int baseScore;

  const LeadSource(this.label, this.code, this.baseScore);
}
