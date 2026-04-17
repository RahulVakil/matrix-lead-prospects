enum IbDealType {
  ecm('ECM'),
  dcm('DCM'),
  ma('M&A'),
  privateEquity('Private Equity / Fundraising'),
  structuredFinance('Structured Finance'),
  other('Other');

  final String label;
  const IbDealType(this.label);
}

enum IbDealStage {
  earlyExploration('Early Exploration'),
  activeDiscussion('Active Discussion'),
  mandateExpectedSoon('Mandate Expected Soon'),
  mandateReceived('Mandate Received');

  final String label;
  const IbDealStage(this.label);
}

enum IbDealValueRange {
  upTo10Cr('< ₹10 Cr', 0, 100000000),
  range10To50Cr('₹10 – 50 Cr', 100000000, 500000000),
  range50To100Cr('₹50 – 100 Cr', 500000000, 1000000000),
  range100To500Cr('₹100 – 500 Cr', 1000000000, 5000000000),
  above500Cr('₹500 Cr +', 5000000000, 99999999999);

  final String label;
  final double minValue;
  final double maxValue;
  const IbDealValueRange(this.label, this.minValue, this.maxValue);

  static IbDealValueRange fromValue(double v) {
    for (final r in values) {
      if (v >= r.minValue && v < r.maxValue) return r;
    }
    return upTo10Cr;
  }
}

/// User-facing IB statuses are 4: Lead Created / Sent Back / Approved /
/// Dropped or Closed. Internally we keep [draft] + [pending] as separate enum
/// cases for backward-compat with mock data and notifier code, but BOTH show
/// the label "Lead Created" — every newly created IB lead is auto-routed to
/// the Admin / MIS review queue, so there is no separate "Sent For Review".
enum IbLeadStatus {
  draft('Lead Created'),
  pending('Lead Created'),
  approved('Approved'),
  sentBack('Sent Back'),
  forwarded('Approved'), // legacy alias; treated as Approved in UI
  dropped('Dropped');

  final String label;
  const IbLeadStatus(this.label);

  /// True when the lead is visible to the IB user.
  bool get isApproved => this == approved || this == forwarded;

  /// True when the lead is in the Admin / MIS review queue.
  bool get isAwaitingReview => this == pending || this == draft;
}

/// IB lead temperature derived from deal stage + timeline. Mirrors wealth
/// lead temperature semantics with the same Hot/Warm/Cold buckets.
///   Hot   – Red    – mandate-imminent (mandateExpectedSoon / mandateReceived) AND short timeline (<= 6 months)
///   Warm  – Amber  – activeDiscussion OR (any stage with timelineMonths <= 12)
///   Cold  – Blue   – earlyExploration / longer timeline / no signal
enum IbLeadTemperature {
  hot('Hot'),
  warm('Warm'),
  cold('Cold');

  final String label;
  const IbLeadTemperature(this.label);
}

/// Top-level industry buckets shown on the IB capture form. "Other" flips
/// the form into free-text mode via [IbLeadModel.industryOther].
enum IbIndustry {
  technology('Technology / IT-ITES'),
  bfsi('BFSI'),
  pharma('Pharma & Healthcare'),
  manufacturing('Manufacturing'),
  fmcg('FMCG / Consumer'),
  realEstate('Real Estate & Infra'),
  energy('Energy & Power'),
  telecom('Telecom & Media'),
  auto('Auto & Mobility'),
  retail('Retail'),
  education('Education'),
  other('Other');

  final String label;
  const IbIndustry(this.label);
}

/// Coarse deal-size buckets used by the IB capture form's chip selector.
/// Manual entry remains the source of truth — chips just pre-fill it.
/// All values are in INR Crore.
enum IbDealSizeBucket {
  upTo500('< ₹500 Cr', 0, 500, 250),
  range500To1000('₹500 – 1,000 Cr', 500, 1000, 750),
  above1000('₹1,000 Cr +', 1000, 99999, 1500);

  final String label;
  final double minCr;
  final double maxCr;
  /// Typical pre-fill value (Cr) when the chip is tapped.
  final double prefillCr;
  const IbDealSizeBucket(this.label, this.minCr, this.maxCr, this.prefillCr);

  static IbDealSizeBucket fromCr(double cr) {
    if (cr < 500) return upTo500;
    if (cr < 1000) return range500To1000;
    return above1000;
  }
}

/// IB Status Tracking enum — hardcoded per spec. 5 values only.
/// Reminder cadence: weekly (7 days); escalation at day 9.
enum IbProgressStatus {
  inDiscussion('In Discussion'),
  proposalSent('Proposal Sent'),
  onHold('On Hold'),
  closedWon('Closed Won'),
  closedLost('Closed Lost');

  final String label;
  const IbProgressStatus(this.label);

  bool get isClosed => this == closedWon || this == closedLost;
}

enum IbIdentifiedHow {
  clientMeeting('Client Meeting'),
  referral('Referral'),
  industryEvent('Industry Event'),
  inboundEnquiry('Inbound Enquiry'),
  other('Other');

  final String label;
  const IbIdentifiedHow(this.label);
}
