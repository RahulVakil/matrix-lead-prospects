/// Designation captured against a wealth lead (when Individual) or against
/// each Key Contact Person (when Non-Individual). Same five values for both
/// surfaces — the form decides which one to show. "Others" requires a
/// free-text qualifier (mirrors the LeadEntityType.others pattern).
enum LeadDesignation {
  promoter('Promoter'),
  founder('Founder'),
  ceo('CEO'),
  familyOfficeHead('Family Office Head'),
  others('Others');

  final String label;
  const LeadDesignation(this.label);
}
