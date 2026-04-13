import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_empty_state.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

class CheckerQueueScreen extends StatefulWidget {
  const CheckerQueueScreen({super.key});

  @override
  State<CheckerQueueScreen> createState() => _CheckerQueueScreenState();
}

class _CheckerQueueScreenState extends State<CheckerQueueScreen> {
  late List<_QueueItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.generate(8, (i) => _QueueItem(
      leadName: ['Rajesh Mehta', 'Sunita Agarwal', 'Alok Garodia', 'Kavita Sharma',
                 'Vikram Bajaj', 'Priya Singhania', 'Rohit Kapoor', 'Deepa Iyer'][i],
      rmName: ['Priya Sharma', 'Amit Verma', 'Priya Sharma', 'Deepa Nair',
               'Karan Kapoor', 'Neha Singh', 'Priya Sharma', 'Amit Verma'][i],
      submittedAt: DateTime.now().subtract(Duration(hours: [4, 12, 24, 36, 48, 52, 60, 72][i])),
      aumEstimate: [15000000.0, 8000000.0, 50000000.0, 3000000.0, 25000000.0, 7500000.0, 12000000.0, 45000000.0][i],
    ));
  }

  void _approve(int index) {
    final name = _items[index].leadName;
    setState(() => _items.removeAt(index));
    showCompassSnack(context, message: 'Profiling approved for $name', type: CompassSnackType.success);
  }

  void _sendBack(int index) {
    final name = _items[index].leadName;
    showCompassSheet(
      context,
      title: 'Send back to RM',
      child: _SendBackBody(
        leadName: name,
        onSubmit: (remarks) {
          Navigator.pop(context);
          setState(() => _items.removeAt(index));
          showCompassSnack(context, message: 'Sent back to RM with remarks', type: CompassSnackType.warn);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(title: 'Profiling pool', subtitle: '${_items.length} pending'),
      body: Column(
        children: [
          Container(
            color: AppColors.surfacePrimary,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statCard('Pending', '${_items.length}', AppColors.warmAmber),
                const SizedBox(width: 12),
                _statCard('Avg TAT', '18h', AppColors.coldBlue),
                const SizedBox(width: 12),
                _statCard('Overdue', '${_items.where((i) => DateTime.now().difference(i.submittedAt).inHours > 48).length}', AppColors.errorRed),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? const CompassEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'All clear',
                    subtitle: 'No profiling reviews pending',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final hoursAgo = DateTime.now().difference(item.submittedAt).inHours;
                      final isOverdue = hoursAgo > 48;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOverdue ? AppColors.errorRed.withValues(alpha: 0.3) : AppColors.cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(item.leadName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                                            if (isOverdue) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.errorRed.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('OVERDUE', style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.errorRed, fontWeight: FontWeight.w700, fontSize: 9,
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
                                        Text(
                                          'Submitted ${hoursAgo}h ago',
                                          style: AppTextStyles.caption.copyWith(
                                            color: isOverdue ? AppColors.errorRed : AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: OutlinedButton(
                                        onPressed: () => _sendBack(index),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.warmAmber,
                                          side: const BorderSide(color: AppColors.warmAmber),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Send Back', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () => _approve(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.successGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.heading2.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatAum(double aum) {
    if (aum >= 10000000) return '₹${(aum / 10000000).toStringAsFixed(1)} Cr';
    if (aum >= 100000) return '₹${(aum / 100000).toStringAsFixed(1)} L';
    return '₹${aum.toStringAsFixed(0)}';
  }
}

class _QueueItem {
  final String leadName;
  final String rmName;
  final DateTime submittedAt;
  final double aumEstimate;
  _QueueItem({required this.leadName, required this.rmName, required this.submittedAt, required this.aumEstimate});
}

class _SendBackBody extends StatefulWidget {
  final String leadName;
  final ValueChanged<String> onSubmit;
  const _SendBackBody({required this.leadName, required this.onSubmit});

  @override
  State<_SendBackBody> createState() => _SendBackBodyState();
}

class _SendBackBodyState extends State<_SendBackBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _ctrl,
          label: 'Remarks',
          isRequired: true,
          hint: 'Why is this being sent back?',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        CompassButton.danger(
          label: 'Send back to RM',
          onPressed: _ctrl.text.trim().isNotEmpty
              ? () => widget.onSubmit(_ctrl.text.trim())
              : null,
        ),
      ],
    );
  }
}
