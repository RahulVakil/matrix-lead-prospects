import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_top_bar.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// My Team — TL aggregate dashboard. KPIs, source breakdown, lead funnel,
/// RM list (self-tile highlighted), and recent activity feed.
///
/// Every metric is tappable and drills to /leads with the right filter
/// pre-applied so the TL can browse the underlying clients in any bucket.
class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    final tlName = user?.name ?? 'Team Lead';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const HeaderTopBar(title: 'Leads · Team'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  const _KpiGrid(),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'By source'),
                  const SizedBox(height: 10),
                  _SourcesCard(),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Lead funnel'),
                  const SizedBox(height: 10),
                  _FunnelCard(),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Engagement level'),
                  const SizedBox(height: 10),
                  _TemperatureCard(),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Team members'),
                  const SizedBox(height: 10),
                  _SelfTile(name: tlName),
                  const SizedBox(height: 8),
                  ..._mockRms.map(
                    (rm) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RmTile(rm: rm),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Recent team activity'),
                  const SizedBox(height: 10),
                  _ActivityFeed(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        color: const Color(0xFF0F172A),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// KPI grid — Total / Active / IB / Onboarded — all tappable
// ─────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: 'TOTAL',
            value: 125,
            icon: Icons.groups_2_outlined,
            onTap: () => context.push(
              RouteNames.leads,
              extra: {'title': 'Team · All leads'},
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            label: 'ACTIVE',
            value: 78,
            icon: Icons.run_circle_outlined,
            accent: AppColors.successGreen,
            onTap: () => context.push(
              RouteNames.leads,
              extra: {
                'title': 'Team · Active leads',
                'activeOnly': true,
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            label: 'IB',
            value: 12,
            icon: Icons.business_center_outlined,
            accent: const Color(0xFF7C3AED),
            // IB combines ib_pending + ib_approved per spec. Cubit doesn't
            // support multi-stage filter yet, so we land on ib_pending —
            // user toggles inside the list to widen. Title makes the
            // intent self-explanatory.
            onTap: () => context.push(
              RouteNames.leads,
              extra: {
                'title': 'Team · IB leads',
                'lifecycle': 'ib_pending',
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            label: 'ONBOARDED',
            value: 35,
            icon: Icons.task_alt,
            accent: const Color(0xFF059669),
            onTap: () => context.push(
              RouteNames.leads,
              extra: {
                'title': 'Team · Onboarded',
                'lifecycle': 'onboarded',
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? accent;
  final VoidCallback onTap;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.navyPrimary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 6),
              Text(
                value.toString().padLeft(2, '0'),
                style: GoogleFonts.roboto(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF586173),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sources card — each row tappable
// ─────────────────────────────────────────────────────────────────────

class _SourceRow {
  final String label;
  final int count;
  final Color color;
  final String sourceKey; // matches LeadSource.name
  const _SourceRow(this.label, this.count, this.color, this.sourceKey);
}

/// Reusable "View N more / Show less" toggle for collapsible sections.
class _ViewMoreToggle extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;
  const _ViewMoreToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expanded ? 'Show less' : 'View $hiddenCount more',
              style: GoogleFonts.roboto(
                color: AppColors.navyPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.navyPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcesCard extends StatefulWidget {
  @override
  State<_SourcesCard> createState() => _SourcesCardState();
}

class _SourcesCardState extends State<_SourcesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Canonical sources from LeadSource enum — 5 RM-addable + 2
    // system-assigned (Hurun, Monetization Event). Counts reconcile to
    // total = 125 (matches KPI tile).
    const all = [
      _SourceRow('Client Referral', 30, Color(0xFF0D9488), 'referral'),
      _SourceRow('Self-generated', 25, AppColors.navyPrimary, 'selfGenerated'),
      _SourceRow('Hurun', 18, Color(0xFFB45309), 'hurun'),
      _SourceRow('Campaign', 18, Color(0xFFEA580C), 'campaign'),
      _SourceRow('Digital', 14, Color(0xFF7C3AED), 'digital'),
      _SourceRow('Monetization Event', 10, Color(0xFF059669),
          'monetizationEvent'),
      _SourceRow('Tele-Calling', 10, Color(0xFF94A3B8), 'teleCalling'),
    ];
    // Sort by count descending so top-3 surface the largest buckets.
    final sorted = [...all]..sort((a, b) => b.count.compareTo(a.count));
    final sources = _expanded ? sorted : sorted.take(3).toList();
    final hidden = sorted.length - sources.length;
    final total = sorted.fold<int>(0, (s, r) => s + r.count);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          ...List.generate(sources.length, (i) {
            final r = sources[i];
            final isLast = i == sources.length - 1 && hidden == 0;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push(
                      RouteNames.leads,
                      extra: {
                        'title': 'Team · ${r.label}',
                        'source': r.sourceKey,
                      },
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: r.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.label,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: r.count / total,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFEDF0F5),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(r.color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 28,
                            child: Text(
                              r.count.toString().padLeft(2, '0'),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.roboto(
                                color: r.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            );
          }),
          if (sorted.length > 3)
            _ViewMoreToggle(
              expanded: _expanded,
              hiddenCount: hidden,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Lead funnel — replaces the old "By temperature" card
// Each step is tappable → /leads filtered to that stage.
// ─────────────────────────────────────────────────────────────────────

class _FunnelStep {
  final String label;
  final int count;
  final Color color;
  final String filterKey;
  const _FunnelStep(this.label, this.count, this.color, this.filterKey);
}

class _FunnelCard extends StatefulWidget {
  @override
  State<_FunnelCard> createState() => _FunnelCardState();
}

class _FunnelCardState extends State<_FunnelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Counts reconcile with the KPI grid:
    //   Active 78 = 22+44+7+5
    //   IB     12 = 7+5
    //   Onboarded 35
    //   Total  125 = 78+35+12 dropped (dropped excluded from the funnel
    //                 since it's a leak, not a step)
    const all = [
      _FunnelStep('Lead', 22, Color(0xFF64748B), 'lead'),
      _FunnelStep('Contacted', 44, Color(0xFF0D9488), 'contacted'),
      _FunnelStep('IB Pending', 7, Color(0xFFEA580C), 'ib_pending'),
      _FunnelStep('IB Approved', 5, Color(0xFF7C3AED), 'ib_approved'),
      _FunnelStep('Onboarded', 35, Color(0xFF059669), 'onboarded'),
    ];
    final sorted = [...all]..sort((a, b) => b.count.compareTo(a.count));
    final steps = _expanded ? sorted : sorted.take(3).toList();
    final hidden = sorted.length - steps.length;
    final maxCount =
        sorted.fold<int>(0, (m, s) => s.count > m ? s.count : m);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          ...List.generate(steps.length, (i) {
            final s = steps[i];
            final isLast = i == steps.length - 1 && hidden == 0;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push(
                      RouteNames.leads,
                      extra: {
                        'title': 'Team · ${s.label}',
                        'lifecycle': s.filterKey,
                      },
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: s.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: Text(
                              s.label,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.count / maxCount,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFEDF0F5),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(s.color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              s.count.toString().padLeft(2, '0'),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.roboto(
                                color: s.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            );
          }),
          if (sorted.length > 3) _ViewMoreToggle(
            expanded: _expanded,
            hiddenCount: hidden,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Temperature card (Hot / Warm / Cold) — funnel-style horizontal bars,
// each row tappable → /leads filtered by temperature.
// ─────────────────────────────────────────────────────────────────────

class _TempBucket {
  final String label;
  final int count;
  final Color color;
  final String tempKey;
  const _TempBucket(this.label, this.count, this.color, this.tempKey);
}

class _TemperatureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final buckets = const [
      _TempBucket('Hot', 28, AppColors.hotRed, 'hot'),
      _TempBucket('Warm', 32, AppColors.warmAmber, 'warm'),
      _TempBucket('Cold', 18, AppColors.coldBlue, 'cold'),
    ];
    final maxCount =
        buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: List.generate(buckets.length, (i) {
          final b = buckets[i];
          final isLast = i == buckets.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(
                    RouteNames.leads,
                    extra: {
                      'title': 'Team · ${b.label}',
                      'status': b.tempKey,
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: b.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 90,
                          child: Text(
                            b.label,
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: b.count / maxCount,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFEDF0F5),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(b.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 32,
                          child: Text(
                            b.count.toString().padLeft(2, '0'),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.roboto(
                              color: b.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Self tile — TL's own row, highlighted, tap → MatrixHome (own pool)
// ─────────────────────────────────────────────────────────────────────

class _SelfTile extends StatelessWidget {
  final String name;
  const _SelfTile({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'TL';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyPrimary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Self-tile → own MatrixHome (full daily commander view of own pool).
        // Player-coach gets Tasks + Meetings + Leads card for their own work.
        onTap: () => context.go('/home'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.navyPrimary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: GoogleFonts.roboto(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.navyPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total ${_selfInfo.total} · Active ${_selfInfo.active} · Onboarded ${_selfInfo.onboarded} (${_selfInfo.onboardedPct}%)',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF586173),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.navyPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// RM tile — tap → /leads-dashboard with rmId/rmName extras (TL view)
// ─────────────────────────────────────────────────────────────────────

class _RmInfo {
  final String id;
  final String name;
  final int total;
  final int active;
  final int onboarded;
  const _RmInfo(this.id, this.name, this.total, this.active, this.onboarded);

  int get onboardedPct =>
      total == 0 ? 0 : ((onboarded * 100) / total).round();
}

const _mockRms = <_RmInfo>[
  _RmInfo('R-101', 'Aanya Khanna', 25, 12, 8),
  _RmInfo('R-102', 'Vikram Mehta', 20, 8, 6),
  _RmInfo('R-103', 'Rohan Kapoor', 18, 6, 5),
  _RmInfo('R-104', 'Asha Krishnan', 12, 4, 4),
  _RmInfo('R-105', 'Patel Family Office', 30, 10, 8),
];

/// Self-tile mock counts — kept consistent with the home Leads card.
const _selfInfo = _RmInfo('R-self', 'self', 12, 8, 3);

class _RmTile extends StatelessWidget {
  final _RmInfo rm;
  const _RmTile({required this.rm});

  String get _initials {
    final parts = rm.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return rm.name.isNotEmpty ? rm.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          RouteNames.leadsDashboard,
          extra: {'rmId': rm.id, 'rmName': rm.name},
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                  _initials,
                  style: GoogleFonts.roboto(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total ${rm.total} · Active ${rm.active} · Onboarded ${rm.onboarded} (${rm.onboardedPct}%)',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF586173),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Activity feed — recent team activity
// ─────────────────────────────────────────────────────────────────────

class _ActivityItem {
  final String rmName;
  final IconData icon;
  final String summary;
  final DateTime when;
  const _ActivityItem({
    required this.rmName,
    required this.icon,
    required this.summary,
    required this.when,
  });
}

/// Relative-time format per spec:
///   < 24h    → "Nh ago"
///   24h–48h  → "yesterday"
///   > 48h    → date in "dd MMM" form (e.g. "06 May")
String _formatRelative(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (h <= 0) {
      final m = diff.inMinutes;
      return m <= 0 ? 'just now' : '${m}m ago';
    }
    return '${h}h ago';
  }
  if (diff.inHours < 48) return 'yesterday';
  return DateFormat('dd MMM').format(when);
}

class _ActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Pull most-recent 5; uses real DateTime so the time labels render
    // via _formatRelative at build time.
    final now = DateTime.now();
    final items = <_ActivityItem>[
      _ActivityItem(
          rmName: 'Aanya Khanna',
          icon: Icons.phone_outlined,
          summary: 'logged a call with Khanna',
          when: now.subtract(const Duration(hours: 2))),
      _ActivityItem(
          rmName: 'Vikram Mehta',
          icon: Icons.trending_up,
          summary: 'moved Holdings → IB Pending',
          when: now.subtract(const Duration(hours: 6))),
      _ActivityItem(
          rmName: 'Rohan Kapoor',
          icon: Icons.do_disturb_on_outlined,
          summary: 'dropped Mehra · Lost - Competitor',
          when: now.subtract(const Duration(hours: 14))),
      _ActivityItem(
          rmName: 'Asha Krishnan',
          icon: Icons.event_outlined,
          summary: 'logged a meeting with Patel Family',
          when: now.subtract(const Duration(hours: 30))), // → "yesterday"
      _ActivityItem(
          rmName: 'Aanya Khanna',
          icon: Icons.person_add_alt_1,
          summary: 'captured a new lead — Hurun list',
          when: now.subtract(const Duration(hours: 60))), // → "06 May"
    ].take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: List.generate(items.length, (i) {
          final it = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color:
                            AppColors.navyPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(it.icon,
                          size: 14, color: AppColors.navyPrimary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF41414E),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: it.rmName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A)),
                            ),
                            TextSpan(text: ' ${it.summary}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRelative(it.when),
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}

// Suppress unused import warnings — keep enums imported for future extension.
// ignore: unused_element
LeadStage? _unusedLeadStageRef() => LeadStage.lead;
