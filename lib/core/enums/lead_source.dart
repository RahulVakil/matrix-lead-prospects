/// Lead source. The first 5 values are RM-pickable on the Add Lead form.
/// `hurun` and `monetizationEvent` are SYSTEM-ASSIGNED tags for pool leads
/// originating from those programs (the Add Lead form filters them out via
/// [addableValues]). They surface as KPIs on the Leadership dashboard.
enum LeadSource {
  selfGenerated('Self-generated', 'SRC_SLF'),
  referral('Client Referral', 'SRC_REF'),
  campaign('Campaign', 'SRC_CAM'),
  digital('Digital', 'SRC_DIG'),
  teleCalling('Tele-Calling', 'SRC_TEL'),
  // System-assigned (not on Add Lead form):
  hurun('Hurun', 'SRC_HUR'),
  monetizationEvent('Monetization Event', 'SRC_EVT');

  final String label;
  final String code;

  const LeadSource(this.label, this.code);

  /// True when this source can be selected by RMs in the Add Lead form.
  /// System-assigned sources (hurun / monetizationEvent) return false.
  bool get isAddable =>
      this != LeadSource.hurun && this != LeadSource.monetizationEvent;

  /// Subset of values shown as RM-pickable chips on the Add Lead form.
  static List<LeadSource> get addableValues =>
      LeadSource.values.where((s) => s.isAddable).toList(growable: false);
}
