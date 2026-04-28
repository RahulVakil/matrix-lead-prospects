/// One row from a coverage data source — Client Master, Company Master,
/// or Lead List. Used by Coverage Check to show RMs whether a person/entity
/// is already covered.
enum CoverageSource {
  clientMaster('Client Master'),
  companyMaster('Company Master'),
  leadList('Lead List');

  final String label;
  const CoverageSource(this.label);
}

class ClientMasterRecord {
  final String id;
  final String clientName;
  final String? groupName;
  final String? rmName;
  final String? rmId;
  final String? phone;
  final String? email;
  final String? city;
  final CoverageSource source;
  final DateTime lastUpdated;

  const ClientMasterRecord({
    required this.id,
    required this.clientName,
    this.groupName,
    this.rmName,
    this.rmId,
    this.phone,
    this.email,
    this.city,
    required this.source,
    required this.lastUpdated,
  });
}
