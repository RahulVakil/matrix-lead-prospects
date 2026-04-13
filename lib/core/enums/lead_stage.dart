import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lead pipeline: Lead → Profiling → Engage → Onboard.
/// Profiling happens BEFORE engagement — research the prospect first,
/// then schedule meetings. Onboard = account opened in Wealth Spectrum.
enum LeadStage {
  lead('Lead', 'S1', AppColors.stageNew, 1),
  profiling('Profiling', 'S2', AppColors.stageProfiling, 2),
  engage('Engage', 'S3', AppColors.stageEngage, 3),
  onboard('Onboard', 'S4', AppColors.stageClient, 4),
  parked('Parked', 'P', AppColors.dormantGray, 0),
  lostCompetitor('Lost - Competitor', 'L1', AppColors.errorRed, 0),
  lostNotInterested('Lost - Not Interested', 'L2', AppColors.errorRed, 0),
  lostTiming('Lost - Timing', 'L3', AppColors.errorRed, 0),
  dormant('Dormant', 'D', AppColors.dormantGray, 0);

  final String label;
  final String code;
  final Color color;
  final int order;

  const LeadStage(this.label, this.code, this.color, this.order);

  bool get isActive => order > 0;
  bool get isTerminal => this == onboard || isLost;
  bool get isLost =>
      this == lostCompetitor ||
      this == lostNotInterested ||
      this == lostTiming;

  LeadStage? get nextStage {
    switch (this) {
      case lead:
        return profiling;
      case profiling:
        return engage;
      case engage:
        return onboard;
      default:
        return null;
    }
  }

  int get slaDays {
    switch (this) {
      case lead:
        return 1; // 24 hours first contact
      case profiling:
        return 5; // research window
      case engage:
        return 7; // meeting within a week
      case onboard:
        return 3; // account opening SLA
      default:
        return 0;
    }
  }

  int get dormantTriggerDays {
    switch (this) {
      case lead:
        return 2;
      case profiling:
        return 7;
      case engage:
        return 10;
      default:
        return 0;
    }
  }

  /// Active pipeline stages in order (for dashboard funnel).
  static const activePipeline = [lead, profiling, engage, onboard];
}
