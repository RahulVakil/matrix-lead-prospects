import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Wealth-CRM lifecycle status set + per-viewer reassignment pills.
/// Covers every scenario surfaced on lead cards / home rollups.
enum LeadDashStatus {
  lead('Lead', Color(0xFF64748B)),                // slate
  contacted('Contacted', Color(0xFF0D9488)),       // teal
  ibPending('IB Pending', Color(0xFFEA580C)),      // amber-orange
  ibApproved('IB Approved', Color(0xFF7C3AED)),    // violet
  onboarded('Onboarded', Color(0xFF059669)),       // green
  dropped('Dropped', Color(0xFFDC2626)),           // red
  reassignedToMe('Reassigned to me', AppColors.navyPrimary),
  reassignedAway('Reassigned away', Color(0xFF94A3B8));

  final String label;
  final Color color;
  const LeadDashStatus(this.label, this.color);

  bool get isReassignmentPill =>
      this == reassignedToMe || this == reassignedAway;
  bool get isTerminal => this == onboarded || this == dropped;
}

/// Status pill with a leading dot, tinted background, and matching text.
/// Two sizes: standard (default) and dense (lead-card use).
class LeadStatusPill extends StatelessWidget {
  final LeadDashStatus status;
  final bool dense;
  const LeadStatusPill({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final hPad = dense ? 7.0 : 10.0;
    final vPad = dense ? 3.0 : 4.0;
    final dotSize = dense ? 5.0 : 6.0;
    final fontSize = dense ? 10.5 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration:
                BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          SizedBox(width: dense ? 5 : 6),
          Text(
            status.label,
            style: GoogleFonts.roboto(
              color: status.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
