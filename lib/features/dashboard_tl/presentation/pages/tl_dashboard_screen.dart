import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

class TlDashboardScreen extends StatelessWidget {
  const TlDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(title: 'Team dashboard', subtitle: 'Pipeline overview'),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          // Team summary cards
          Text('TEAM OVERVIEW', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiCard('Total Leads', '67', AppColors.navyPrimary),
              const SizedBox(width: 12),
              _kpiCard('Hot', '12', AppColors.hotRed),
              const SizedBox(width: 12),
              _kpiCard('Conversions', '4', AppColors.successGreen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Tap to open the team's IB Leads list (TL view of My IB Leads).
              _kpiCard(
                'IB Leads',
                '9',
                AppColors.stageOpportunity,
                onTap: () => context.push('/ib-leads'),
              ),
              const SizedBox(width: 12),
              _kpiCard('Dropped', '8', AppColors.errorRed),
              const SizedBox(width: 12),
              _kpiCard('In Pool', '15', AppColors.coldBlue),
            ],
          ),
          const SizedBox(height: 24),

          // Pipeline by stage
          Text('PIPELINE BY STAGE', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),
          _pipelineBar(),
          const SizedBox(height: 24),

          // RM-wise breakdown
          Text('RM PERFORMANCE', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),
          _rmRow(context, 'RM001', 'Priya Sharma', 18, 4, 82, AppColors.successGreen),
          _rmRow(context, 'RM002', 'Amit Verma', 15, 2, 65, AppColors.warmAmber),
          _rmRow(context, 'RM003', 'Deepa Nair', 12, 1, 71, AppColors.successGreen),
          _rmRow(context, 'RM004', 'Karan Kapoor', 14, 3, 58, AppColors.warmAmber),
          _rmRow(context, 'RM005', 'Neha Singh', 8, 0, 45, AppColors.errorRed),
          const SizedBox(height: 24),

          // Recent activity
          Text('TEAM ACTIVITY (LAST 24H)', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),
          _activityStat(Icons.phone, 'Calls Made', '34'),
          _activityStat(Icons.calendar_today, 'Meetings Scheduled', '8'),
          _activityStat(Icons.note_alt_outlined, 'Notes Logged', '22'),
          _activityStat(Icons.arrow_upward, 'Stage Advances', '6'),
          _activityStat(Icons.trending_down, 'Leads Lost', '2'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading1.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
    return Expanded(
      child: onTap == null
          ? card
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: card,
            ),
    );
  }

  Widget _pipelineBar() {
    // Canonical funnel stages per spec: Lead → Profiling → Engage → Onboarded.
    final stages = [
      ('Lead', 15, AppColors.stageNew),
      ('Profiling', 8, AppColors.stageProfiling),
      ('Engage', 22, AppColors.stageEngage),
      ('Onboarded', 4, AppColors.stageClient),
    ];
    final total = stages.fold<int>(0, (sum, s) => sum + s.$2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: stages.map((s) {
                return Expanded(
                  flex: s.$2,
                  child: Container(
                    height: 24,
                    color: s.$3,
                    alignment: Alignment.center,
                    child: Text('${s.$2}', style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stages.map((s) => Text(s.$1, style: AppTextStyles.caption)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _rmRow(BuildContext context, String rmId, String name, int leads, int conversions, int avgScore, Color scoreColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/leads-dashboard', extra: {'rmId': rmId, 'rmName': name}),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.avatarBackground,
              child: Text(name.split(' ').map((w) => w[0]).take(2).join(), style: AppTextStyles.caption.copyWith(color: AppColors.navyDark, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  Text('$leads leads  ·  $conversions converted', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$avgScore', style: AppTextStyles.labelSmall.copyWith(color: scoreColor, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
      ),
    );
  }

  Widget _activityStat(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.labelLarge.copyWith(color: AppColors.navyPrimary)),
        ],
      ),
    );
  }
}
