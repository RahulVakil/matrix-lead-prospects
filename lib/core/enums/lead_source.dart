/// Lead source. The first 5 values are RM-pickable on the Add Lead form.
/// `hurun` and `monetizationEvent` are SYSTEM-ASSIGNED tags for pool leads
/// originating from those programs (the Add Lead form filters them out via
/// [addableValues]). They surface as KPIs on the Leadership dashboard.
enum LeadSource {
  selfGenerated('Self-generated', 'SRC_SLF', 20),
  referral('Client Referral', 'SRC_REF', 30),
  campaign('Campaign', 'SRC_CAM', 15),
  digital('Digital', 'SRC_DIG', 12),
  teleCalling('Tele-Calling', 'SRC_TEL', 18),
  // System-assigned (not on Add Lead form):
  hurun('Hurun', 'SRC_HUR', 28),
  monetizationEvent('Monetization Event', 'SRC_EVT', 30);

  final String label;
  final String code;
  final int baseScore;

  const LeadSource(this.label, this.code, this.baseScore);

  /// True when this source can be selected by RMs in the Add Lead form.
  /// System-assigned sources (hurun / monetizationEvent) return false.
  bool get isAddable =>
      this != LeadSource.hurun && this != LeadSource.monetizationEvent;

  /// Subset of values shown as RM-pickable chips on the Add Lead form.
  static List<LeadSource> get addableValues =>
      LeadSource.values.where((s) => s.isAddable).toList(growable: false);
}
