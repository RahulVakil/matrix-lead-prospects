/// Whether the lead is an individual person or a non-individual entity.
enum LeadEntityType {
  individual('Individual'),
  nonIndividual('Non-Individual');

  final String label;
  const LeadEntityType(this.label);
}

/// Sub-type for Non-Individual leads.
enum LeadSubType {
  partnership('Partnership'),
  llp('LLP'),
  huf('HUF'),
  privateLtd('Private Limited'),
  publicLtd('Public Limited'),
  trust('Trust'),
  society('Society'),
  other('Other');

  final String label;
  const LeadSubType(this.label);
}
