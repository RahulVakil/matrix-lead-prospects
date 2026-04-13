/// Retention lifecycle status per DPDP Act.
/// Leads are auto-flagged after 180 days of inactivity.
enum RetentionStatus {
  active('Active', 'Within retention window'),
  flaggedForReview('Review needed', 'Inactive 180+ days — review or extend'),
  retentionExtended('Extended', 'Retention manually extended by RM'),
  markedForDeletion('Deletion requested', 'Pending admin approval for permanent deletion'),
  deleted('Deleted', 'Personal data permanently removed');

  final String label;
  final String description;

  const RetentionStatus(this.label, this.description);
}
