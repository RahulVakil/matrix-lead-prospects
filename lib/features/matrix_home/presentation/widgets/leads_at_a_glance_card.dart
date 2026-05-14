import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// Leads section on home — section header + a pipeline-led smart card.
///
/// Card layers:
///   1. Headline — Active count + conversion %
///   2. Stacked horizontal pipeline bar (one segment per lifecycle stage)
///   3. Stage list (vertical, tappable) — covers all 6 lifecycle stages
///      followed by 2 reassignment rows under a "Reassignment" sub-header.
///      Tapping any row pushes /leads with a stage or reassignment filter
///      pre-applied so the destination shows ONLY clients in that bucket.
///   4. Actionable nudge — "N follow-ups due today" → /follow-ups/today
class LeadsAtAGlanceCard extends StatelessWidget {
  const LeadsAtAGlanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Source data — 6 lifecycle stages + 2 reassignment subsets ────
    // Math model:
    //   total      = sum of lifecycle counts
    //   active     = sum of non-terminal lifecycle counts
    //                (everything except Onboarded + Dropped)
    //   conversion = onboarded / total
    //   reassignment counts are PER-VIEWER OVERLAYS — subsets of `total`,
    //   NOT additive to lifecycle counts. They render in the list with
    //   a "subset" treatment so they don't read as additive buckets.
    const lifecycleStages = <_StageBucket>[
      _StageBucket(
          label: 'Lead',
          count: 4,
          color: Color(0xFF64748B),
          filterKey: 'lead'),
      _StageBucket(
          label: 'Contacted',
          count: 5,
          color: Color(0xFF0D9488),
          filterKey: 'contacted'),
      _StageBucket(
          label: 'IB Pending',
          count: 2,
          color: Color(0xFFEA580C),
          filterKey: 'ib_pending'),
      _StageBucket(
          label: 'IB Approved',
          count: 1,
          color: Color(0xFF7C3AED),
          filterKey: 'ib_approved'),
      _StageBucket(
          label: 'Onboarded',
          count: 8,
          color: Color(0xFF059669),
          filterKey: 'onboarded',
          isTerminal: true),
      _StageBucket(
          label: 'Dropped',
          count: 3,
          color: Color(0xFFDC2626),
          filterKey: 'dropped',
          isTerminal: true),
    ];
    const reassignmentRows = <_StageBucket>[
      _StageBucket(
          label: 'Reassigned to me',
          count: 2,
          color: AppColors.navyPrimary,
          reassignmentKey: 'to_me',
          isSubset: true),
      _StageBucket(
          label: 'Reassigned away',
          count: 2,
          color: Color(0xFF94A3B8),
          reassignmentKey: 'away',
          isSubset: true),
    ];

    // Derived numbers — single source of truth = the stage data above.
    final total = lifecycleStages.fold<int>(0, (s, b) => s + b.count);
    final active = lifecycleStages
        .where((b) => !b.isTerminal)
        .fold<int>(0, (s, b) => s + b.count);
    final onboarded = lifecycleStages
        .firstWhere((b) => b.filterKey == 'onboarded',
            orElse: () => const _StageBucket(
                label: '', count: 0, color: Colors.transparent))
        .count;
    final conversionPct =
        total == 0 ? 0 : ((onboarded * 100) / total).round();
    const followUpsToday = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header (matches Tasks / Meetings) ───────────────
        Row(
          children: [
            Text(
              'Leads',
              style: GoogleFonts.roboto(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              // Title badge = TOTAL (sum of lifecycle stages). This matches
              // the sum of the 6 lifecycle rows in the list below, so the
              // math reconciles at a glance.
              child: Text(
                total.toString().padLeft(2, '0'),
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.push(RouteNames.leadsDashboard),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
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
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right,
                        color: AppColors.navyPrimary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Card ────────────────────────────────────────────────────
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(RouteNames.leadsDashboard),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline row — Active (in pipeline) + total + conv %.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        active.toString().padLeft(2, '0'),
                        style: GoogleFonts.roboto(
                          color: AppColors.navyPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF586173),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'of $total total',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up,
                                size: 12,
                                color: AppColors.successGreen),
                            const SizedBox(width: 4),
                            Text(
                              '$conversionPct% conv',
                              style: GoogleFonts.roboto(
                                color: AppColors.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Tap → opens a plain-language explainer of the
                      // numbers (active/total/conv + the subset note).
                      InkWell(
                        onTap: () => _showMathExplainer(
                          context,
                          active: active,
                          total: total,
                          onboarded: onboarded,
                          dropped: lifecycleStages
                              .firstWhere(
                                (b) => b.filterKey == 'dropped',
                                orElse: () => const _StageBucket(
                                    label: '',
                                    count: 0,
                                    color: Colors.transparent),
                              )
                              .count,
                          conversionPct: conversionPct,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pipeline stacked bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: lifecycleStages.map((s) {
                          return Expanded(
                            flex: s.count == 0 ? 1 : s.count,
                            child: Container(
                              decoration: BoxDecoration(
                                color: s.count == 0
                                    ? const Color(0xFFEDF0F5)
                                    : s.color,
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.white,
                                    width: s == lifecycleStages.last
                                        ? 0
                                        : 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Single continuous status list — all 8 (6 lifecycle +
                  // 2 reassignment), sorted highest to lowest by count
                  // so the buckets the RM has the most of surface first.
                  // Pipeline bar above stays in funnel order — bar shows
                  // *position*, list shows *volume*.
                  _StageList(
                    rows: ([
                      ...lifecycleStages,
                      ...reassignmentRows,
                    ]..sort((a, b) => b.count.compareTo(a.count))),
                    collapsedCount: 3,
                  ),
                  const SizedBox(height: 12),

                  // Actionable nudge
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () =>
                          context.push(RouteNames.followUpsToday),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.warmAmber.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warmAmber
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.warmAmber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.roboto(
                                    color: const Color(0xFF8A4F00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$followUpsToday leads ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const TextSpan(
                                        text: 'need follow-up today'),
                                  ],
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 16, color: AppColors.warmAmber),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet that explains where each number on the Leads card comes
/// from. Triggered by the small ⓘ icon next to the conversion pill so it's
/// discoverable but stays out of the way for users who don't need it.
void _showMathExplainer(
  BuildContext context, {
  required int active,
  required int total,
  required int onboarded,
  required int dropped,
  required int conversionPct,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.navyPrimary),
                const SizedBox(width: 8),
                Text(
                  'How the numbers work',
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF0A1629),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ExplainerRow(
              number: '$active',
              label: 'Active',
              meaning:
                  'Leads still in flight — Lead + Contacted + IB Pending + IB Approved.',
            ),
            const SizedBox(height: 12),
            _ExplainerRow(
              number: '$total',
              label: 'Total',
              meaning:
                  'Every lead you have worked. Active + Onboarded + Dropped.',
            ),
            const SizedBox(height: 12),
            _ExplainerRow(
              number: '$conversionPct%',
              label: 'Conv',
              meaning:
                  'Of $total total leads, $onboarded became clients. '
                  'Calculated as Onboarded ÷ Total.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.navyPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reassignment counts ("Reassigned to me / away") are '
                      'SUBSETS — they\'re already counted in your active '
                      'leads, not added on top.',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF41414E),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExplainerRow extends StatelessWidget {
  final String number;
  final String label;
  final String meaning;
  const _ExplainerRow({
    required this.number,
    required this.label,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: GoogleFonts.roboto(
                  color: AppColors.navyPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: const Color(0xFF586173),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              meaning,
              style: GoogleFonts.roboto(
                color: const Color(0xFF41414E),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageBucket {
  final String label;
  final int count;
  final Color color;
  final String? filterKey;       // lifecycle stage filter token
  final String? reassignmentKey; // 'to_me' / 'away'
  final bool isTerminal;         // Onboarded / Dropped — out of "active"
  final bool isSubset;           // reassignment overlay (not additive)
  const _StageBucket({
    required this.label,
    required this.count,
    required this.color,
    this.filterKey,
    this.reassignmentKey,
    this.isTerminal = false,
    this.isSubset = false,
  });
}

class _StageList extends StatefulWidget {
  final List<_StageBucket> rows;
  final int collapsedCount;
  const _StageList({required this.rows, required this.collapsedCount});

  @override
  State<_StageList> createState() => _StageListState();
}

class _StageListState extends State<_StageList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.rows.length;
    final shown = _expanded
        ? widget.rows
        : widget.rows.take(widget.collapsedCount).toList();
    final hiddenCount = total - widget.collapsedCount;
    final hasMore = hiddenCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          ...List.generate(shown.length, (i) {
            final s = shown[i];
            final isLast = i == shown.length - 1 && !hasMore;
            return Column(
              children: [
                _StageRow(stage: s),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.7),
                    indent: 12,
                    endIndent: 12,
                  ),
              ],
            );
          }),
          if (hasMore)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'View $hiddenCount more',
                      style: GoogleFonts.roboto(
                        color: AppColors.navyPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.navyPrimary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final _StageBucket stage;
  const _StageRow({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(
          RouteNames.leads,
          extra: {
            'title': stage.label,
            if (stage.filterKey != null) 'lifecycle': stage.filterKey,
            if (stage.reassignmentKey != null)
              'reassignment': stage.reassignmentKey,
          },
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: stage.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        stage.label,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (stage.isSubset) ...[
                      const SizedBox(width: 6),
                      // Visual cue that this row is a per-viewer overlay,
                      // NOT additive to the lifecycle counts above.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'subset',
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                stage.count.toString().padLeft(2, '0'),
                style: GoogleFonts.roboto(
                  color: stage.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right,
                  size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
