import 'package:flutter/material.dart';
import '../enums/lead_stage.dart';
import '../theme/app_text_styles.dart';

class StageBadge extends StatelessWidget {
  final LeadStage stage;
  final bool dense;

  const StageBadge({super.key, required this.stage, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stage.label,
        style: (dense ? AppTextStyles.caption : AppTextStyles.labelSmall)
            .copyWith(color: stage.color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
