enum LeadSource {
  selfGenerated('Self Generated', 'SRC_SLF', 20),
  hurun('Hurun', 'SRC_HUR', 25),
  vcCircle('VC Circle', 'SRC_VCC', 22),
  referral('Referral', 'SRC_REF', 30),
  ifa('IFA Partner', 'SRC_IFA', 25),
  campaign('Campaign', 'SRC_CAM', 15),
  digital('Digital', 'SRC_DIG', 12);

  final String label;
  final String code;
  final int baseScore;

  const LeadSource(this.label, this.code, this.baseScore);
}
