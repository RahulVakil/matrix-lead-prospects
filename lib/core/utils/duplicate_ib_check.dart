import '../enums/ib_deal_type.dart';
import '../models/ib_lead_model.dart';

/// Global Rule #1: One active IB lead per client at any time.
/// An IB lead is "active" if its latest progress status is NOT terminal
/// (Mandate Won / Mandate Lost / Declined) and the workflow status is
/// not Dropped.
class DuplicateIbCheck {
  DuplicateIbCheck._();

  /// Returns the blocking IB lead ID if [clientName] already has an active
  /// IB lead in [allIbLeads], or `null` if creation is allowed.
  static String? findActiveIbLead(
    String clientName,
    List<IbLeadModel> allIbLeads,
  ) {
    final normalised = clientName.trim().toLowerCase();
    if (normalised.isEmpty) return null;
    for (final ib in allIbLeads) {
      final ibClient = (ib.clientName ?? ib.companyName).trim().toLowerCase();
      if (ibClient == normalised && _isActive(ib)) {
        return ib.id;
      }
    }
    return null;
  }

  static bool _isActive(IbLeadModel ib) {
    final s = ib.latestProgressStatus;
    if (s != null && s.isTerminal) return false;
    // Also treat the workflow-level "dropped" as inactive.
    if (ib.status == IbLeadStatus.dropped) return false;
    return true;
  }
}
