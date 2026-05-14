import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';
import 'lead_status_pill.dart';
import 'leads_hero_card.dart';

class _LeadPreview {
  final String id;
  final String name;
  final String summary; // e.g. "EWG · Mumbai"
  final LeadDashStatus stage;
  final LeadDashStatus? reassignmentPill;
  _LeadPreview({
    required this.id,
    required this.name,
    required this.summary,
    required this.stage,
    this.reassignmentPill,
  });
}

/// "Leads Dashboard" section on home.
///
/// Order of contents:
///   1. Section header (title + Show all link)
///   2. Blue gradient hero card — active leads, dropped subtitle,
///      Lead→Onboarded conversion, and Hot/Warm/Cold mini-bars
///      (mirrors _TotalHeroCard from LeadsDashboardScreen)
///   3. "Recent 3 active leads" subheader
///   4. Three lead rows with lifecycle + reassignment pills
///
/// "Show all" → /leads (LeadInboxScreen) — full filterable list.
class MyLeadsSection extends StatelessWidget {
  const MyLeadsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final leads = <_LeadPreview>[
      _LeadPreview(
        id: 'L-1042',
        name: 'Aanya Khanna',
        summary: 'EWG · Mumbai · captured 2d ago',
        stage: LeadDashStatus.contacted,
      ),
      _LeadPreview(
        id: 'L-1037',
        name: 'Vikram Holdings Pvt Ltd',
        summary: 'PWG · Bengaluru · IB docs awaited',
        stage: LeadDashStatus.ibPending,
        reassignmentPill: LeadDashStatus.reassignedToMe,
      ),
      _LeadPreview(
        id: 'L-1029',
        name: 'Rohan Kapoor',
        summary: 'EWG · Pune · just captured',
        stage: LeadDashStatus.lead,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Leads Dashboard',
              style: GoogleFonts.roboto(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.push(RouteNames.leads),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                // Material guideline 48dp min hit area — keep tap target generous.
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Show all',
                      style: GoogleFonts.roboto(
                        color: AppColors.navyPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.navyPrimary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Mock counts. Production: derive from a /leads/home-summary endpoint
        // that reuses the same metrics LeadsDashboardCubit already produces
        // (totalLeads, droppedCount, pipeline[], hot/warm/cold).
        const LeadsHeroCard(
          active: 12,
          dropped: 3,
          onboarded: 8,
          funnelTotal: 23,
          hot: 4,
          warm: 5,
          cold: 3,
        ),
        const SizedBox(height: 18),
        Text(
          'Recent 3 active leads',
          style: GoogleFonts.roboto(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...leads.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeadRow(lead: l),
            )),
      ],
    );
  }
}

class _LeadRow extends StatelessWidget {
  final _LeadPreview lead;
  const _LeadRow({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RouteNames.leadDetailPath(lead.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.avatarBackground.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                  style: GoogleFonts.roboto(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lead.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LeadStatusPill(status: lead.stage, dense: true),
                        if (lead.reassignmentPill != null)
                          LeadStatusPill(
                              status: lead.reassignmentPill!, dense: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
