import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LeadTemperature {
  hot('Hot', AppColors.hotRed, Icons.local_fire_department, 75, 100),
  warm('Warm', AppColors.warmAmber, Icons.wb_sunny_outlined, 50, 74),
  cold('Cold', AppColors.coldBlue, Icons.ac_unit, 0, 49),
  dormant('Dormant', AppColors.dormantGray, Icons.pause_circle_outline, -1, -1);

  final String label;
  final Color color;
  final IconData icon;
  final int minScore;
  final int maxScore;

  const LeadTemperature(
      this.label, this.color, this.icon, this.minScore, this.maxScore);

  static LeadTemperature fromScore(int score, {bool isDormant = false}) {
    if (isDormant) return dormant;
    if (score >= 75) return hot;
    if (score >= 50) return warm;
    return cold;
  }

  Color get backgroundColor => color.withValues(alpha: 0.1);
}
