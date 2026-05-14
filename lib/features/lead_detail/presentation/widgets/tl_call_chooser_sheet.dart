import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

/// What the TL chose on the Call tile when viewing a reportee's lead.
enum TlCallChoice { callNow, viewLogs }

/// Bottom sheet shown on tap of the Call tile when the viewer is a TL
/// looking at a reportee's lead. TL has two paths:
///   1. **Call now** — launches the dialer. No log entry is created on
///      return — only the RM owns the activity log.
///   2. **View call logs** — opens a read-only list of every call the RM
///      has logged for this lead.
class TlCallChooserSheet {
  static Future<TlCallChoice?> show(
    BuildContext context, {
    required String leadName,
    required String? phone,
    required int loggedCallCount,
  }) {
    return showCompassSheet<TlCallChoice>(
      context,
      title: 'Call $leadName',
      child: _Body(phone: phone, loggedCallCount: loggedCallCount),
    );
  }
}

class _Body extends StatelessWidget {
  final String? phone;
  final int loggedCallCount;
  const _Body({required this.phone, required this.loggedCallCount});

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Read-only context banner — TL is not the owner.
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
          icon: Icons.phone_in_talk_outlined,
          color: AppColors.successGreen,
          title: 'Call now',
          subtitle: hasPhone
              ? 'Launches your dialer. No log entry will be created.'
              : 'No phone on record for this lead',
          enabled: hasPhone,
          onTap: () => Navigator.of(context).pop(TlCallChoice.callNow),
        ),
        const SizedBox(height: 12),
        _option(
          context,
          icon: Icons.history,
          color: AppColors.navyPrimary,
          title: 'View call logs',
          subtitle: loggedCallCount == 0
              ? 'No calls logged for this lead yet'
              : 'Read every call the RM has logged · '
                  '$loggedCallCount entr${loggedCallCount == 1 ? "y" : "ies"}',
          enabled: true,
          onTap: () => Navigator.of(context).pop(TlCallChoice.viewLogs),
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
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
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
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
