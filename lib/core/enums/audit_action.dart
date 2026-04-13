/// Actions tracked in the DPDP audit trail.
enum AuditAction {
  viewPII('Viewed PII', 'Accessed personally identifiable information'),
  editPII('Edited PII', 'Modified personally identifiable information'),
  exportData('Exported data', 'Generated a data portability report'),
  deletePII('Deleted PII', 'Requested or executed data deletion'),
  viewCoverage('Ran coverage check', 'Searched coverage database for a person/family'),
  downloadReport('Downloaded report', 'Downloaded a lead or client report'),
  unmaskField('Unmasked field', 'Viewed full value of a masked PII field');

  final String label;
  final String description;

  const AuditAction(this.label, this.description);
}
