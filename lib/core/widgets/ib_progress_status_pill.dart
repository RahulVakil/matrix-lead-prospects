import 'package:flutter/material.dart';
import '../enums/ib_deal_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compact pill that surfaces an IB lead's latest 30-day progress status on
/// listing rows. Pass [null] to render the "Awaiting first update" variant —
/// useful for approved leads that have no progress entries yet so the user
/// can spot stalled hand-offs at a glance.
class IbProgressStatusPill extends StatelessWidget {
  final IbProgressStatus? status;
  const IbProgressStatusPill({super.key, this.status});

  Color get _color {
    final s = status;
    if (s == null) return AppColors.dormantGray;
    if (s == IbProgressStatus.mandateWon) return AppColors.successGreen;
    if (s == IbProgressStatus.mandateLost ||
        s == IbProgressStatus.declined) {
      return AppColors.errorRed;
    }
    return AppColors.navyPrimary;
  }

  String get _label => status?.label ?? 'Awaiting update';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: AppTextStyles.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }
}
