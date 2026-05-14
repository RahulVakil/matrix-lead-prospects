import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// FAB sheet for All Leads / Leads Dashboard. Three lead-related entries:
///   1. New Lead   → /leads/new       (capture a new wealth lead)
///   2. Get New Lead → /get-lead      (claim from RM-pool)
///   3. Track IB Leads → /ib-leads    (open the IB leads list)
class LeadsAddSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Root navigator so the sheet sits cleanly on top of the bottom
      // nav rather than clipping above it.
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      builder: (_) => const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  'What would you like to do?',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Tile(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'New Lead',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.createLead);
                  },
                ),
                _Tile(
                  icon: Icons.move_to_inbox_rounded,
                  label: 'Get New Lead',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.getLead);
                  },
                ),
                _Tile(
                  icon: Icons.business_center_rounded,
                  label: 'Track IB Leads',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.ibLeads);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.67),
      child: SizedBox(
        width: 96,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                width: 73,
                height: 73,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF7F8FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.67)),
                ),
                child: Icon(icon, size: 28, color: AppColors.navyPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF41414E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
