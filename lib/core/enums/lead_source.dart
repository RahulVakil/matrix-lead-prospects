enum LeadSource {
  referral('Referral', 'SRC_REF', 30),
  ifa('IFA Partner', 'SRC_IFA', 25),
  selfGenerated('Self-generated', 'SRC_SLF', 20),
  seminar('Seminar/Event', 'SRC_SEM', 20),
  campaign('Campaign', 'SRC_CAM', 15),
  website('Website/Digital', 'SRC_WEB', 15),
  coldCall('Cold Call', 'SRC_CLD', 5),
  walkIn('Walk-in', 'SRC_WLK', 10);

  final String label;
  final String code;
  final int baseScore;

  const LeadSource(this.label, this.code, this.baseScore);
}
