import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

enum TlMeetingChoice { meetNow, viewLogs }

/// Bottom sheet shown on tap of the Meet tile when the viewer is a TL
/// looking at a reportee's lead.
///   1. **Meet now** — placeholder action; production opens the calendar
///      invite / video link. No log entry is created.
///   2. **View logged meetings** — read-only list of every meeting the RM
///      has logged for this lead.
class TlMeetingChooserSheet {
  static Future<TlMeetingChoice?> show(
    BuildContext context, {
    required String leadName,
    required int loggedMeetingCount,
  }) {
    return showCompassSheet<TlMeetingChoice>(
      context,
      title: 'Meeting with $leadName',
      child: _Body(loggedMeetingCount: loggedMeetingCount),
    );
  }
}

class _Body extends StatelessWidget {
  final int loggedMeetingCount;
  const _Body({required this.loggedMeetingCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warmAmber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.warmAmber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 14, color: AppColors.warmAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Read-only · You can't log on the RM's behalf.",
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8A4F00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _option(
          context,
          icon: Icons.event_available,
          color: AppColors.successGreen,
          title: 'Meet now',
          subtitle:
              'Opens the calendar / video link. No log entry will be created.',
          onTap: () => Navigator.of(context).pop(TlMeetingChoice.meetNow),
        ),
        const SizedBox(height: 12),
        _option(
          context,
          icon: Icons.history,
          color: AppColors.navyPrimary,
          title: 'View logged meetings',
          subtitle: loggedMeetingCount == 0
              ? 'No meetings logged for this lead yet'
              : 'Read every meeting the RM has logged · '
                  '$loggedMeetingCount entr${loggedMeetingCount == 1 ? "y" : "ies"}',
          onTap: () => Navigator.of(context).pop(TlMeetingChoice.viewLogs),
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
