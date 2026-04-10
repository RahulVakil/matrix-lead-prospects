import 'package:flutter/material.dart';
import '../enums/lead_temperature.dart';
import '../theme/app_text_styles.dart';

class TempPill extends StatelessWidget {
  final LeadTemperature temperature;
  final bool showLabel;

  const TempPill({
    super.key,
    required this.temperature,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: temperature.color,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: temperature.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: temperature.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            temperature.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: temperature.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
