import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'compass_snackbar.dart';

/// Bottom-sheet chooser for the "+" FAB across the app. Offers two paths:
///   (1) New Wealth Lead → /leads/new
///   (2) New IB Lead → blocked unless [parentLeadId] provided; otherwise shows
///       an informational message directing the RM to convert from a wealth lead.
void showCreateChooser(
  BuildContext rootContext, {
  String? parentLeadId,
}) {
  showModalBottomSheet<void>(
    context: rootContext,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Create new',
              style:
                  AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ChooserTile(
              icon: Icons.person_add_alt_1,
              color: AppColors.tealAccent,
              label: 'New wealth lead',
              caption: 'Capture an individual or family lead',
              onTap: () {
                Navigator.of(sheetContext).pop();
                rootContext.push('/leads/new');
              },
            ),
            const SizedBox(height: 10),
            ChooserTile(
              icon: Icons.business_center_outlined,
              color: AppColors.stageOpportunity,
              label: 'New IB lead',
              caption:
                  'Must originate from an existing wealth lead or client',
              onTap: () {
                Navigator.of(sheetContext).pop();
                // Block direct IB creation (#9) — RM must convert from a
                // wealth lead detail screen.
                showCompassSnack(
                  rootContext,
                  message:
                      'Open a wealth lead → 3-dot menu → Convert to IB Lead',
                  type: CompassSnackType.warn,
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class ChooserTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String caption;
  final VoidCallback onTap;
  const ChooserTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(caption,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
