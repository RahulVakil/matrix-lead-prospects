/// The flat list of entity types the wealth team captures today. Replaces
/// the older Individual / Non-Individual binary plus a separate sub-type
/// dropdown — the team prefers a single decision in the Add Lead form.
enum LeadEntityType {
  individual('Individual'),
  partnership('Partnership'),
  llp('LLP'),
  huf('HUF'),
  privateLtd('Private Limited'),
  publicLtd('Public Limited'),
  trust('Trust'),
  society('Society'),
  others('Others');

  final String label;
  const LeadEntityType(this.label);

  /// True when the lead is a natural person — drives the First/Middle/Last
  /// name layout vs the single Entity Name field, and gates the Key Contact
  /// Person section (which only applies to non-individual entities).
  bool get isIndividual => this == LeadEntityType.individual;
}
