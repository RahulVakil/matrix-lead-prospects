import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';

enum CallChoice { callNow, logPast }

/// Bottom sheet shown on tap of the Call tile. Lets the RM either dial the
/// lead directly (`tel:`) or log a past call. On `callNow` the dialer is
/// launched and the caller is asked to log on return.
class CallActionChooserSheet {
  static Future<CallChoice?> show(
    BuildContext context, {
    required String leadName,
    required String? phone,
  }) {
    return showCompassSheet<CallChoice>(
      context,
      title: 'Call $leadName',
      child: _Body(phone: phone),
    );
  }

  /// Launches the platform dialer for [phone]. Returns true on success.
  static Future<bool> launchDialer(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

class _Body extends StatelessWidget {
  final String? phone;
  const _Body({required this.phone});

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _option(
          context,
          icon: Icons.phone_in_talk_outlined,
          color: AppColors.successGreen,
          title: 'Call now',
          subtitle: hasPhone
              ? 'Launches your dialer; we\'ll prompt you to log when you\'re back.'
              : 'No phone on record for this lead',
          enabled: hasPhone,
          onTap: () => Navigator.of(context).pop(CallChoice.callNow),
        ),
        const SizedBox(height: 12),
        _option(
          context,
          icon: Icons.edit_calendar_outlined,
          color: AppColors.navyPrimary,
          title: 'Log a past call',
          subtitle: 'You already spoke — capture the details and outcome.',
          enabled: true,
          onTap: () => Navigator.of(context).pop(CallChoice.logPast),
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
                Icon(
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
