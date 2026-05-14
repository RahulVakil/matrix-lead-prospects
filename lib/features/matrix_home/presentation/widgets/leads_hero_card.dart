import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// KPI hero used at the top of the All-leads list. MATRIX-native styling:
///   - White surface, 12-px radius, soft black-6% shadow at offset (0, 2)
///   - Navy primary text and accents (instead of the prior blue gradient)
///   - 16-px padding, Roboto throughout
///
/// Hierarchy:
///   Default — Active count + Lead→Onboarded conversion ring on a single
///             ~80-px-tall row. Toggle icon (chevron) at the top-right.
///   Expanded — Reveals Hot / Warm / Cold mini-bars below the headline.
class LeadsHeroCard extends StatefulWidget {
  final int active;
  final int dropped;
  final int onboarded;
  final int funnelTotal;
  final int hot;
  final int warm;
  final int cold;

  const LeadsHeroCard({
    super.key,
    required this.active,
    required this.dropped,
    required this.onboarded,
    required this.funnelTotal,
    required this.hot,
    required this.warm,
    required this.cold,
  });

  @override
  State<LeadsHeroCard> createState() => _LeadsHeroCardState();
}

class _LeadsHeroCardState extends State<LeadsHeroCard> {
  bool _expanded = false;

  double get _conversionPercent {
    if (widget.funnelTotal == 0) return 0;
    return (widget.onboarded / widget.funnelTotal) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Active
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: widget.active.toDouble()),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(
                            '${v.round()}',
                            style: GoogleFonts.roboto(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyPrimary,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'Active',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF586173),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.dropped > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.dropped} dropped · ${widget.active + widget.dropped} total',
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: const Color(0xFFEDF0F5),
              ),
              const SizedBox(width: 10),
              // Conversion
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    _ConversionRing(percent: _conversionPercent, size: 38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lead → Onboarded',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF586173),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${widget.onboarded} of ${widget.funnelTotal == 0 ? 1 : widget.funnelTotal}',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _expanded ? 'Hide breakdown' : 'Show breakdown',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.navyPrimary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 6, 2),
                    child: Column(
                      children: [
                        _TempRow(
                            label: 'Hot',
                            count: widget.hot,
                            total: widget.active,
                            color: AppColors.hotRed),
                        const SizedBox(height: 8),
                        _TempRow(
                            label: 'Warm',
                            count: widget.warm,
                            total: widget.active,
                            color: AppColors.warmAmber),
                        const SizedBox(height: 8),
                        _TempRow(
                            label: 'Cold',
                            count: widget.cold,
                            total: widget.active,
                            color: AppColors.coldBlue),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ConversionRing extends StatelessWidget {
  final double percent;
  final double size;
  const _ConversionRing({required this.percent, required this.size});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent.clamp(0, 100)),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: v / 100,
                strokeWidth: 3.5,
                backgroundColor: const Color(0xFFEDF0F5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.successGreen),
              ),
            ),
            Text(
              '${v.round()}%',
              style: GoogleFonts.roboto(
                color: AppColors.navyPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _TempRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                color: const Color(0xFF41414E),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$count',
              style: GoogleFonts.roboto(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.roboto(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 4,
              backgroundColor: const Color(0xFFEDF0F5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
