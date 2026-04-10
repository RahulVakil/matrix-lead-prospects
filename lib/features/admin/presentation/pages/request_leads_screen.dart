import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';

class RequestLeadsScreen extends StatefulWidget {
  const RequestLeadsScreen({super.key});

  @override
  State<RequestLeadsScreen> createState() => _RequestLeadsScreenState();
}

class _RequestLeadsScreenState extends State<RequestLeadsScreen> {
  bool _isEligible = true;
  int _currentCapacity = 12;
  int _maxCapacity = 20;
  int _requestedCount = 0;

  @override
  Widget build(BuildContext context) {
    final availableSlots = _maxCapacity - _currentCapacity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leads'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          // Capacity banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyPrimary, AppColors.navyPrimary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('YOUR LEAD CAPACITY', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.7), letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _capacityStat('$_currentCapacity', 'Current'),
                    Container(width: 1, height: 40, color: AppColors.textOnDark.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _capacityStat('$_maxCapacity', 'Maximum'),
                    Container(width: 1, height: 40, color: AppColors.textOnDark.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _capacityStat('$availableSlots', 'Available'),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentCapacity / _maxCapacity,
                    backgroundColor: AppColors.textOnDark.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      availableSlots > 5 ? AppColors.successGreen : AppColors.warmAmber,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_isEligible) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warmAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warmAmber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are not eligible for new leads at this time. Complete pending activities on existing leads first.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.warmAmber),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text('REQUEST NEW LEADS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How many leads would you like?', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _requestedCount > 0 ? () => setState(() => _requestedCount--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.navyPrimary,
                      ),
                      Text('$_requestedCount', style: AppTextStyles.heading1),
                      IconButton(
                        onPressed: _requestedCount < availableSlots ? () => setState(() => _requestedCount++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.navyPrimary,
                      ),
                      const Spacer(),
                      Text('Max: $availableSlots', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leads will be assigned from the available pool based on your vertical and region.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _requestedCount > 0 ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request for $_requestedCount leads submitted to your Team Lead'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: AppColors.textOnDark,
                  disabledBackgroundColor: AppColors.disabledButton,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                ),
                child: Text('Submit Request', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _capacityStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading1.copyWith(color: AppColors.textOnDark)),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.7))),
      ],
    );
  }
}
