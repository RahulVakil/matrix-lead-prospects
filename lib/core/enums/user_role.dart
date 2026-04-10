enum UserRole {
  rm('Relationship Manager', 'RM'),
  teamLead('Team Lead', 'TL'),
  branchManager('Branch Manager', 'BM'),
  checker('Checker', 'CHK'),
  compliance('Compliance', 'CMP'),
  admin('Admin', 'ADM'),
  management('Management', 'MGT');

  final String label;
  final String code;

  const UserRole(this.label, this.code);

  bool get canCreateLead =>
      this == rm || this == teamLead || this == branchManager || this == admin;

  bool get canEditLead =>
      this == rm || this == teamLead || this == branchManager || this == admin;

  bool get canAdvanceStage =>
      this == rm || this == teamLead || this == branchManager || this == admin;

  bool get canReassignLead =>
      this == teamLead || this == branchManager || this == admin;

  bool get canApproveProfile => this == checker;

  bool get canBulkAssign => this == admin;

  bool get canViewAllLeads =>
      this == compliance || this == admin || this == management;

  bool get canViewTeamLeads =>
      this == teamLead || this == branchManager || this == admin;
}
