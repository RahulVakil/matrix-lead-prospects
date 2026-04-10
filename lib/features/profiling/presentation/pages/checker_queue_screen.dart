import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';

class CheckerQueueScreen extends StatelessWidget {
  const CheckerQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock profiling queue data
    final queueItems = List.generate(8, (i) => _QueueItem(
      leadName: ['Rajesh Mehta', 'Sunita Agarwal', 'Alok Garodia', 'Kavita Sharma',
                 'Vikram Bajaj', 'Priya Singhania', 'Rohit Kapoor', 'Deepa Iyer'][i],
      rmName: ['Priya Sharma', 'Amit Verma', 'Priya Sharma', 'Deepa Nair',
               'Karan Kapoor', 'Neha Singh', 'Priya Sharma', 'Amit Verma'][i],
      submittedAt: DateTime.now().subtract(Duration(hours: [4, 12, 24, 36, 48, 52, 60, 72][i])),
      aumEstimate: [15000000.0, 8000000.0, 50000000.0, 3000000.0, 25000000.0, 7500000.0, 12000000.0, 45000000.0][i],
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checker Queue'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statCard('Pending', '${queueItems.length}', AppColors.warmAmber),
                const SizedBox(width: 12),
                _statCard('Avg TAT', '18h', AppColors.coldBlue),
                const SizedBox(width: 12),
                _statCard('Overdue', '2', AppColors.errorRed),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              itemCount: queueItems.length,
              itemBuilder: (context, index) {
                final item = queueItems[index];
                final hoursAgo = DateTime.now().difference(item.submittedAt).inHours;
                final isOverdue = hoursAgo > 48;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                      border: Border.all(
                        color: isOverdue ? AppColors.errorRed.withValues(alpha: 0.3) : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(item.leadName, style: AppTextStyles.labelLarge),
                                  if (isOverdue) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('OVERDUE', style: AppTextStyles.caption.copyWith(
                                        color: AppColors.errorRed, fontWeight: FontWeight.w600, fontSize: 9,
                                      )),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM: ${item.rmName}  ·  AUM: ${_formatAum(item.aumEstimate)}',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submitted ${hoursAgo}h ago',
                                style: AppTextStyles.caption.copyWith(
                                  color: isOverdue ? AppColors.errorRed : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening review for ${item.leadName}'), backgroundColor: AppColors.tealAccent),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealAccent,
                            foregroundColor: AppColors.textOnDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                          ),
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatAum(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(0)} L';
    return '₹${amount.toStringAsFixed(0)}';
  }
}

class _QueueItem {
  final String leadName;
  final String rmName;
  final DateTime submittedAt;
  final double aumEstimate;

  _QueueItem({required this.leadName, required this.rmName, required this.submittedAt, required this.aumEstimate});
}
