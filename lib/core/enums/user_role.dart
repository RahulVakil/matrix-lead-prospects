/// Five-level org hierarchy used by the Leadership dashboard:
///   RM (own) → TL (team) → Regional (region) → Zonal (zone) → CEO/Admin (all).
/// Compliance / Management / IB are operational roles outside the hierarchy.
enum UserRole {
  rm('Relationship Manager', 'RM'),
  teamLead('Team Lead', 'TL'),
  regional('Regional Head', 'RH'),
  zonal('Zonal Head', 'ZH'),
  ceo('CEO', 'CEO'),
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
  /// True for any role that should see leads outside their own pipeline:
  /// the leadership chain (TL/Regional/Zonal/CEO) plus oversight roles.
  bool get canViewAllLeads =>
      this == compliance ||
      this == admin ||
      this == management ||
      this == regional ||
      this == zonal ||
      this == ceo;
  bool get canViewTeamLeads =>
      this == teamLead ||
      this == admin ||
      this == regional ||
      this == zonal ||
      this == ceo;
  bool get isIB => this == ib;

  /// Natural data scope for the Leadership dashboard. RM has its own
  /// (personal-pipeline) screen; the four leadership roles below all share
  /// `LeadershipDashboardScreen` with different scope filters.
  LeadershipLevel? get leadershipLevel {
    switch (this) {
      case UserRole.teamLead:
        return LeadershipLevel.team;
      case UserRole.regional:
        return LeadershipLevel.region;
      case UserRole.zonal:
        return LeadershipLevel.zone;
      case UserRole.admin:
      case UserRole.ceo:
      case UserRole.management:
        return LeadershipLevel.all;
      default:
        return null;
    }
  }
}

/// The four levels of the leadership dashboard. Each level shows a children
/// breakdown table that drills down into the next level (zone → region →
/// team → RM). Reaching `team` and tapping an RM row navigates into the
/// RM's own LeadsDashboardScreen.
enum LeadershipLevel {
  team,
  region,
  zone,
  all;

  String get label {
    switch (this) {
      case LeadershipLevel.team:
        return 'Team';
      case LeadershipLevel.region:
        return 'Regional';
      case LeadershipLevel.zone:
        return 'Zone';
      case LeadershipLevel.all:
        return 'Organisation';
    }
  }

  /// The level below this one in the drill-down hierarchy. `team` is the
  /// leaf — drilling further from team enters the RM dashboard.
  LeadershipLevel? get childLevel {
    switch (this) {
      case LeadershipLevel.all:
        return LeadershipLevel.zone;
      case LeadershipLevel.zone:
        return LeadershipLevel.region;
      case LeadershipLevel.region:
        return LeadershipLevel.team;
      case LeadershipLevel.team:
        return null;
    }
  }
}
