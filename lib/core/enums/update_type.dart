import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Type tag for entries on the merged Lead Detail timeline.
enum TimelineEntryType {
  activity('Activity', Icons.history, AppColors.textSecondary),
  statusUpdate('Status Update', Icons.flag_outlined, AppColors.warmAmber),
  stageChange('Stage Change', Icons.trending_up, AppColors.navyPrimary),
  dealEdit('Deal Updated', Icons.edit_note, AppColors.tealAccent),
  ibLeadCreated('IB Lead Created', Icons.business_center, AppColors.stageOpportunity),
  systemEvent('System', Icons.settings, AppColors.dormantGray);

  final String label;
  final IconData icon;
  final Color color;

  const TimelineEntryType(this.label, this.icon, this.color);
}

/// Quick status RM can attach to a lead via the Quick Update sheet.
enum LeadUpdateStatus {
  noUpdate('No Update', AppColors.dormantGray),
  hot('Hot', AppColors.hotRed),
  warm('Warm', AppColors.warmAmber),
  cold('Cold', AppColors.coldBlue),
  stalled('Stalled', AppColors.dormantGray),
  won('Won', AppColors.successGreen),
  lost('Lost', AppColors.errorRed);

  final String label;
  final Color color;

  const LeadUpdateStatus(this.label, this.color);
}
