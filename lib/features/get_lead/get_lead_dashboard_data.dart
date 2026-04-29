/// Aggregate counts for the simplified Get Lead screen.
/// Per the demo-ready spec we surface only: total pool size + the two
/// per-RM lifetime KPIs (Total Requested / Total Converted from Pool).
/// The weekly cap and wrong-contact bonus model has been retired.
class GetLeadDashboardData {
  /// Total leads currently sitting in the shared pool.
  final int totalPoolLeads;

  /// Lifetime count of leads this RM has requested from the pool.
  final int leadsRequestedItd;

  /// Lifetime count of pool-origin leads this RM has Onboarded.
  final int poolLeadsConvertedItd;

  const GetLeadDashboardData({
    required this.totalPoolLeads,
    required this.leadsRequestedItd,
    required this.poolLeadsConvertedItd,
  });
}
