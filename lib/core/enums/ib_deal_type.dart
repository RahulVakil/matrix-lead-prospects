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

enum IbLeadStatus {
  draft('Draft'),
  pending('Pending Branch Head'),
  approved('Approved'),
  sentBack('Sent Back'),
  forwarded('Forwarded to IB');

  final String label;
  const IbLeadStatus(this.label);
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
