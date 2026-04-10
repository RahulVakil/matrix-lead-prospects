import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';

class PoolManagementScreen extends StatelessWidget {
  const PoolManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Pool Management'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          // Pool stats
          Row(
            children: [
              _statCard('Total in Pool', '47', AppColors.navyPrimary),
              const SizedBox(width: 12),
              _statCard('EWG', '28', AppColors.tealAccent),
              const SizedBox(width: 12),
              _statCard('PWG', '19', AppColors.stageOpportunity),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _statCard('Pending Requests', '5', AppColors.warmAmber),
              const SizedBox(width: 12),
              _statCard('Assigned Today', '8', AppColors.successGreen),
              const SizedBox(width: 12),
              _statCard('Avg Wait', '2.3h', AppColors.coldBlue),
            ],
          ),
          const SizedBox(height: 24),

          Text('PENDING REQUESTS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),

          ...List.generate(5, (i) => _requestCard(
            rmName: ['Priya Sharma', 'Amit Verma', 'Deepa Nair', 'Karan Kapoor', 'Neha Singh'][i],
            vertical: ['EWG', 'PWG', 'EWG', 'EWG', 'PWG'][i],
            count: [3, 2, 5, 1, 4][i],
            hoursAgo: [1, 3, 6, 8, 12][i],
            context: context,
          )),

          const SizedBox(height: 24),
          Text('POOL SOURCES', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: 12),

          _sourceRow('Campaign — Q1 Digital', 15),
          _sourceRow('Seminar — Mumbai Mar 2026', 12),
          _sourceRow('Website Inquiries', 8),
          _sourceRow('IFA Referrals — Batch 12', 7),
          _sourceRow('Cold — Re-engagement', 5),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _requestCard({
    required String rmName,
    required String vertical,
    required int count,
    required int hoursAgo,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rmName, style: AppTextStyles.labelLarge),
                  Text('$vertical  ·  Requested $count leads  ·  ${hoursAgo}h ago', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count leads assigned to $rmName'), backgroundColor: AppColors.successGreen),
                );
              },
              child: Text('Approve', style: AppTextStyles.labelSmall.copyWith(color: AppColors.successGreen)),
            ),
            TextButton(
              onPressed: () {},
              child: Text('Deny', style: AppTextStyles.labelSmall.copyWith(color: AppColors.errorRed)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceRow(String name, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: AppTextStyles.bodyMedium)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count', style: AppTextStyles.labelSmall.copyWith(color: AppColors.navyPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
