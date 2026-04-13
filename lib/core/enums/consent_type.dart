/// Types of data consent captured under DPDP Act 2023.
/// Each lead can have multiple consent records of different types.
enum DataConsentType {
  leadCapture(
    'Lead Capture',
    'Storage of personal data (name, phone, company, investment interest) '
        'for lead management and investment advisory services.',
  ),
  profilingKyc(
    'Profiling & KYC',
    'Collection and verification of identity documents, risk profile, '
        'and investment objectives for regulatory compliance.',
  ),
  communicationPreference(
    'Communication',
    'Contacting you via phone, WhatsApp, email, or SMS for investment '
        'related updates and follow-ups.',
  ),
  dataSharing(
    'Data Sharing',
    'Sharing your data with internal teams (compliance, IB) for '
        'cross-referencing and opportunity identification.',
  );

  final String label;
  final String purposeStatement;

  const DataConsentType(this.label, this.purposeStatement);
}

/// Aggregate consent status for a lead.
enum ConsentStatus {
  pending('Pending', 'No consent recorded yet'),
  granted('Granted', 'All required consents captured'),
  partial('Partial', 'Some consents captured, others pending'),
  revoked('Revoked', 'Consent has been revoked — data flagged for deletion');

  final String label;
  final String description;

  const ConsentStatus(this.label, this.description);
}
