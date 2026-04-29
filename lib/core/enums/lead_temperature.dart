import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wealth lead temperature. Computed from age (`createdAt`) on `LeadModel`,
/// not from a quality score. Dormant overrides everything when stage is set
/// to dormant. See `LeadModel.temperature` for the derivation rule.
enum LeadTemperature {
  hot('Hot', AppColors.hotRed, Icons.local_fire_department),
  warm('Warm', AppColors.warmAmber, Icons.wb_sunny_outlined),
  cold('Cold', AppColors.coldBlue, Icons.ac_unit),
  /// Onboarded is the terminal status — set when stage == LeadStage.onboard.
  /// Surfaced as the 4th value alongside Hot/Warm/Cold in the unified
  /// "Status" filter and the "Lead Funnel" breakdown.
  onboarded('Onboarded', AppColors.successGreen, Icons.verified_outlined),
  dormant('Dormant', AppColors.dormantGray, Icons.pause_circle_outline);

  final String label;
  final Color color;
  final IconData icon;

  const LeadTemperature(this.label, this.color, this.icon);

  Color get backgroundColor => color.withValues(alpha: 0.1);
}
