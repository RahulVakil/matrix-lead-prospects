enum LeadSource {
  selfGenerated('Self-generated', 'SRC_SLF', 20),
  referral('Client Referral', 'SRC_REF', 30),
  campaign('Campaign', 'SRC_CAM', 15),
  digital('Digital', 'SRC_DIG', 12),
  teleCalling('Tele-Calling', 'SRC_TEL', 18);

  final String label;
  final String code;
  final int baseScore;

  const LeadSource(this.label, this.code, this.baseScore);
}
