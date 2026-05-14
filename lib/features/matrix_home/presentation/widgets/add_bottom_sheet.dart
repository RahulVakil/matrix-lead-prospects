import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// Home FAB sheet — mirrors compass_v2_mobile/AddBottomSheet exactly.
/// 6 tiles in a 4-col grid (1.5 rows). Production: every tile is `() {}`.
/// In this prototype, only the **Lead** tile is wired (→ /leads/new) so
/// the FAB demonstrates the lead-create entry from home. Wealth-CRM
/// creation actions (Get Lead / IB Lead) live on the Leads Dashboard FAB.
class AddBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Use the root navigator so the sheet covers the bottom nav bar
      // cleanly instead of clipping above it (otherwise the sheet's
      // bottom edge sits on top of the nav bar and looks broken).
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddSheetContent(),
    );
  }
}

class _AddTile {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _AddTile(this.icon, this.label, this.onTap, {this.primary = false});
}

class _AddSheetContent extends StatelessWidget {
  const _AddSheetContent();

  @override
  Widget build(BuildContext context) {
    final tiles = <_AddTile>[
      _AddTile(Icons.task_alt_rounded, 'Task', null),
      _AddTile(Icons.person_add_alt_1_rounded, 'Lead', () {
        Navigator.pop(context);
        context.push(RouteNames.createLead);
      }, primary: true),
      _AddTile(Icons.event_available_rounded, 'Meeting', null),
      _AddTile(Icons.campaign_rounded, 'Campaign', null),
      _AddTile(Icons.badge_rounded, 'Client', null),
      _AddTile(Icons.sticky_note_2_rounded, 'Note', null),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A1629),
                  ),
                ),
                IconButton(
                  iconSize: 22,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF41414E)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: tiles
                  .map((t) => _AddTileWidget(tile: t))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTileWidget extends StatelessWidget {
  final _AddTile tile;
  const _AddTileWidget({required this.tile});

  @override
  Widget build(BuildContext context) {
    final isStub = tile.onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: tile.onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tile.label} — coming soon'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tile.primary
                  ? AppColors.navyPrimary.withValues(alpha: 0.10)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tile.icon,
              size: 24,
              color: tile.primary
                  ? AppColors.navyPrimary
                  : (isStub ? AppColors.textHint : AppColors.navyDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tile.label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isStub ? AppColors.textHint : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
