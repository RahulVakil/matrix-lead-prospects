enum UserRole {
  rm('Relationship Manager', 'RM'),
  teamLead('Team Lead', 'TL'),
  compliance('Compliance', 'CMP'),
  admin('Admin / MIS', 'ADM'),
  management('Management', 'MGT'),
  ib('Investment Banking', 'IB');

  final String label;
  final String code;

  const UserRole(this.label, this.code);

  bool get canCreateLead => this == rm || this == teamLead || this == admin;
  bool get canEditLead => this == rm || this == teamLead || this == admin;
  bool get canAdvanceStage => this == rm || this == teamLead || this == admin;
  bool get canReassignLead => this == teamLead || this == admin;
  bool get canApproveProfile => this == admin;
  bool get canApproveIB => this == admin || this == ib;
  bool get canBulkAssign => this == admin;
  bool get canViewAllLeads => this == compliance || this == admin || this == management;
  bool get canViewTeamLeads => this == teamLead || this == admin;
  bool get isIB => this == ib;
}
