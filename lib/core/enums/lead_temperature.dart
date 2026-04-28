import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wealth lead temperature. Computed from age (`createdAt`) on `LeadModel`,
/// not from a quality score. Dormant overrides everything when stage is set
/// to dormant. See `LeadModel.temperature` for the derivation rule.
enum LeadTemperature {
  hot('Hot', AppColors.hotRed, Icons.local_fire_department),
  warm('Warm', AppColors.warmAmber, Icons.wb_sunny_outlined),
  cold('Cold', AppColors.coldBlue, Icons.ac_unit),
  dormant('Dormant', AppColors.dormantGray, Icons.pause_circle_outline);

  final String label;
  final Color color;
  final IconData icon;

  const LeadTemperature(this.label, this.color, this.icon);

  Color get backgroundColor => color.withValues(alpha: 0.1);
}
