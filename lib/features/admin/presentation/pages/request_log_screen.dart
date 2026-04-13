import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

class RequestLogScreen extends StatelessWidget {
  const RequestLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = List.generate(15, (i) => _RequestEntry(
      rmName: ['Priya Sharma', 'Amit Verma', 'Deepa Nair', 'Karan Kapoor', 'Neha Singh',
               'Priya Sharma', 'Karan Kapoor', 'Amit Verma', 'Neha Singh', 'Deepa Nair',
               'Priya Sharma', 'Amit Verma', 'Karan Kapoor', 'Deepa Nair', 'Neha Singh'][i],
      vertical: i % 2 == 0 ? 'EWG' : 'PWG',
      count: [3, 2, 5, 1, 4, 3, 2, 5, 1, 4, 2, 3, 1, 4, 2][i],
      status: i < 5 ? 'Pending' : i < 10 ? 'Approved' : 'Denied',
      requestedAt: DateTime.now().subtract(Duration(hours: i * 4 + 1)),
      processedAt: i >= 5 ? DateTime.now().subtract(Duration(hours: i * 3)) : null,
    ));

    return HeroScaffold(
      header: HeroAppBar.simple(title: 'Request log', subtitle: '${requests.length} requests'),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          final statusColor = req.status == 'Approved'
              ? AppColors.successGreen
              : req.status == 'Denied'
                  ? AppColors.errorRed
                  : AppColors.warmAmber;

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
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(req.rmName, style: AppTextStyles.labelLarge),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.status,
                                style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${req.vertical}  ·  ${req.count} leads  ·  Requested ${_timeAgo(req.requestedAt)}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (req.processedAt != null)
                          Text(
                            'Processed ${_timeAgo(req.processedAt!)}',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _RequestEntry {
  final String rmName;
  final String vertical;
  final int count;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;

  _RequestEntry({
    required this.rmName, required this.vertical, required this.count,
    required this.status, required this.requestedAt, this.processedAt,
  });
}
