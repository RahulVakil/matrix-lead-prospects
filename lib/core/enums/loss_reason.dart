enum LossReason {
  competitor('Competitor Won', 90),
  notInterested('Not Interested', 180),
  timing('Bad Timing', 0), // custom reopen date
  budgetRevised('Budget Revised', 90),
  productMismatch('Product Mismatch', 120),
  lostContact('Lost Contact', 60);

  final String label;
  final int reopenDays; // 0 = RM sets custom date

  const LossReason(this.label, this.reopenDays);
}

enum ParkReason {
  travelingAbroad('Traveling Abroad'),
  familyEvent('Family Event'),
  financialPlanning('Financial Planning in Progress'),
  seasonalBusiness('Seasonal Business'),
  other('Other');

  final String label;

  const ParkReason(this.label);
}
