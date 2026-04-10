enum ProfilingStatus {
  notStarted('Not Started'),
  draft('Draft'),
  submitted('Submitted'),
  underReview('Under Review'),
  approved('Approved'),
  rejected('Rejected');

  final String label;
  const ProfilingStatus(this.label);

  bool get isComplete => this == approved;
  bool get isPending => this == submitted || this == underReview;
}

class ProfilingModel {
  final String id;
  final String leadId;
  final ProfilingStatus status;
  final DateTime? submittedAt;
  final String? submittedById;
  final String? submittedByName;
  final DateTime? reviewedAt;
  final String? reviewedById;
  final String? reviewedByName;
  final String? rejectionReason;
  final String? panNumber;
  final bool kycDocumentsReady;
  final bool suitabilityComplete;
  final bool riskProfileComplete;

  ProfilingModel({
    required this.id,
    required this.leadId,
    this.status = ProfilingStatus.notStarted,
    this.submittedAt,
    this.submittedById,
    this.submittedByName,
    this.reviewedAt,
    this.reviewedById,
    this.reviewedByName,
    this.rejectionReason,
    this.panNumber,
    this.kycDocumentsReady = false,
    this.suitabilityComplete = false,
    this.riskProfileComplete = false,
  });

  Duration? get timeInReview {
    if (submittedAt == null || status != ProfilingStatus.underReview) {
      return null;
    }
    return DateTime.now().difference(submittedAt!);
  }

  int get completionStep {
    switch (status) {
      case ProfilingStatus.notStarted:
        return 0;
      case ProfilingStatus.draft:
        return 0;
      case ProfilingStatus.submitted:
        return 1;
      case ProfilingStatus.underReview:
        return 2;
      case ProfilingStatus.approved:
        return 3;
      case ProfilingStatus.rejected:
        return 1;
    }
  }
}
