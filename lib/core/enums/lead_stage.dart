import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LeadStage {
  lead('Lead', 'S1', AppColors.stageNew, 1),
  engage('Engage', 'S2', AppColors.stageEngage, 2),
  opportunity('Opportunity', 'S3', AppColors.stageOpportunity, 3),
  profiling('Profiling', 'S4', AppColors.stageProfiling, 4),
  client('Client', 'S5', AppColors.stageClient, 5),
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
  bool get isTerminal => this == client || isLost;
  bool get isLost =>
      this == lostCompetitor ||
      this == lostNotInterested ||
      this == lostTiming;

  LeadStage? get nextStage {
    switch (this) {
      case lead:
        return engage;
      case engage:
        return opportunity;
      case opportunity:
        return profiling;
      case profiling:
        return client;
      default:
        return null;
    }
  }

  int get slaDays {
    switch (this) {
      case lead:
        return 1; // 24 hours
      case engage:
        return 7;
      case opportunity:
        return 14;
      case profiling:
        return 3; // 72 hours for checker
      default:
        return 0;
    }
  }

  int get dormantTriggerDays {
    switch (this) {
      case lead:
        return 2;
      case engage:
        return 5;
      case opportunity:
        return 10;
      default:
        return 0;
    }
  }
}
