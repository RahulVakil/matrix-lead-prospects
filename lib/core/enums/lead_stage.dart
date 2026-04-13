import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lead pipeline: Lead → Profiling → Engage → Onboard.
/// Dropped = RM has dropped the lead with a mandatory reason.
/// Dropped leads can return to the Get Lead pool if Admin/MIS approves.
enum LeadStage {
  lead('Lead', 'S1', AppColors.stageNew, 1),
  profiling('Profiling', 'S2', AppColors.stageProfiling, 2),
  engage('Engage', 'S3', AppColors.stageEngage, 3),
  onboard('Onboard', 'S4', AppColors.stageClient, 4),
  dropped('Dropped', 'DR', AppColors.errorRed, 0),
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
  bool get isTerminal => this == onboard || isLost || this == dropped;
  bool get isLost =>
      this == lostCompetitor ||
      this == lostNotInterested ||
      this == lostTiming;
  bool get isDropped => this == dropped;

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
        return 1;
      case profiling:
        return 5;
      case engage:
        return 7;
      case onboard:
        return 3;
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

/// Mandatory reason when an RM drops a lead.
enum DropReason {
  notResponding('Not responding', 'Multiple contact attempts with no response'),
  wrongContact('Wrong contact info', 'Phone/email invalid or belongs to someone else'),
  notInterested('Not interested', 'Prospect explicitly declined'),
  duplicateEntry('Duplicate', 'Same person already exists as another lead/client'),
  outsideScope('Outside scope', 'Prospect does not fit our target segment'),
  movedAbroad('Moved abroad', 'Prospect relocated outside serviceable geography'),
  other('Other', 'Custom reason specified by RM');

  final String label;
  final String description;
  const DropReason(this.label, this.description);
}
