/// Aggregate counts shown on the Get Lead Dashboard (RM + TL).
class GetLeadDashboardData {
  final int totalPoolLeads;
  final int leadsRequestedItd;
  final int requestedLeadsDroppedItd;
  final int poolLeadsConvertedItd;
  final int claimsInLast7Days;
  final int wrongContactDropsInLast7Days;

  const GetLeadDashboardData({
    required this.totalPoolLeads,
    required this.leadsRequestedItd,
    required this.requestedLeadsDroppedItd,
    required this.poolLeadsConvertedItd,
    required this.claimsInLast7Days,
    required this.wrongContactDropsInLast7Days,
  });

  /// Base weekly cap is 4. Each wrong-contact drop in the last 7 days grants
  /// +1 exception budget. Returns the effective cap.
  int get effectiveWeeklyCap => 4 + wrongContactDropsInLast7Days;

  /// Leads the RM can still request right now.
  int get remainingThisWeek =>
      (effectiveWeeklyCap - claimsInLast7Days).clamp(0, 1 << 30);
}
