import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

enum MeetingChoice { scheduleNew, logPast }

/// Bottom sheet shown on tap of the Meet tile. Lets the RM either
/// schedule a new meeting (full meeting create flow) or log a past
/// meeting that already happened.
class MeetingActionChooserSheet {
  static Future<MeetingChoice?> show(
    BuildContext context, {
    required String leadName,
  }) {
    return showCompassSheet<MeetingChoice>(
      context,
      title: 'Meeting with $leadName',
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _option(
          context,
          icon: Icons.event_available,
          color: AppColors.navyPrimary,
          title: 'Schedule a new meeting',
          subtitle: 'Set a date, mode, link, and invite the lead.',
          onTap: () => Navigator.of(context).pop(MeetingChoice.scheduleNew),
        ),
        const SizedBox(height: 12),
        _option(
          context,
          icon: Icons.edit_calendar_outlined,
          color: AppColors.warmAmber,
          title: 'Log a past meeting',
          subtitle: 'You\'ve already met — capture the outcome and notes.',
          onTap: () => Navigator.of(context).pop(MeetingChoice.logPast),
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
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
