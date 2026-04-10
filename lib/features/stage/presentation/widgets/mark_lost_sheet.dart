import 'package:flutter/material.dart';
import '../../../../core/enums/loss_reason.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';

class MarkLostSheet extends StatefulWidget {
  final String leadName;
  final void Function(LossReason reason, String? notes, DateTime? reopenDate) onMarkLost;
  final void Function(ParkReason reason, DateTime followUpDate, String? notes)? onPark;

  const MarkLostSheet({
    super.key,
    required this.leadName,
    required this.onMarkLost,
    this.onPark,
  });

  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required void Function(LossReason reason, String? notes, DateTime? reopenDate) onMarkLost,
    void Function(ParkReason reason, DateTime followUpDate, String? notes)? onPark,
  }) {
    return showCompassSheet(
      context,
      title: leadName,
      child: MarkLostSheet(
        leadName: leadName,
        onMarkLost: onMarkLost,
        onPark: onPark,
      ),
    );
  }

  @override
  State<MarkLostSheet> createState() => _MarkLostSheetState();
}

class _MarkLostSheetState extends State<MarkLostSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  LossReason? _lostReason;
  ParkReason? _parkReason;
  final _notes = TextEditingController();
  DateTime? _reopenDate;
  DateTime? _followUpDate;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _showCustomReopen => _lostReason?.reopenDays == 0;

  void _submitLost() {
    if (_lostReason == null) return;
    if (_showCustomReopen && _reopenDate == null) return;
    widget.onMarkLost(
      _lostReason!,
      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      _showCustomReopen
          ? _reopenDate
          : DateTime.now().add(Duration(days: _lostReason!.reopenDays)),
    );
    Navigator.of(context).pop();
  }

  void _submitPark() {
    if (_parkReason == null || _followUpDate == null) return;
    widget.onPark?.call(
      _parkReason!,
      _followUpDate!,
      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorPadding: const EdgeInsets.all(3),
            labelColor: AppColors.errorRed,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.labelSmall,
            dividerHeight: 0,
            tabs: const [
              Tab(text: 'Mark Lost'),
              Tab(text: 'Park Lead'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tab,
            children: [_lostTab(), _parkTab()],
          ),
        ),
      ],
    );
  }

  Widget _lostTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reason', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LossReason.values
                .map((r) => CompassChoiceChip<LossReason>(
                      value: r,
                      groupValue: _lostReason,
                      label: r.label,
                      color: AppColors.errorRed,
                      onSelected: (v) => setState(() => _lostReason = v),
                    ))
                .toList(),
          ),
          if (_lostReason != null) ...[
            const SizedBox(height: 8),
            Text(
              _showCustomReopen
                  ? 'Pick a custom reopen date below.'
                  : 'Auto-reopen after ${_lostReason!.reopenDays} days.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
          const SizedBox(height: 12),
          if (_showCustomReopen)
            CompassDateField(
              label: 'Reopen on',
              value: _reopenDate,
              onChanged: (v) => setState(() => _reopenDate = v),
              firstDate: DateTime.now().add(const Duration(days: 1)),
              isRequired: true,
            ),
          const SizedBox(height: 12),
          CompassTextField(
            controller: _notes,
            label: 'Notes (optional)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CompassButton.danger(
            label: 'Mark as Lost',
            onPressed: _lostReason != null && (!_showCustomReopen || _reopenDate != null)
                ? _submitLost
                : null,
          ),
        ],
      ),
    );
  }

  Widget _parkTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reason', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ParkReason.values
                .map((r) => CompassChoiceChip<ParkReason>(
                      value: r,
                      groupValue: _parkReason,
                      label: r.label,
                      color: AppColors.warmAmber,
                      onSelected: (v) => setState(() => _parkReason = v),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          CompassDateField(
            label: 'Follow up on',
            value: _followUpDate,
            onChanged: (v) => setState(() => _followUpDate = v),
            firstDate: DateTime.now().add(const Duration(days: 1)),
            isRequired: true,
          ),
          const SizedBox(height: 12),
          CompassTextField(
            controller: _notes,
            label: 'Notes (optional)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CompassButton(
            label: 'Park Lead',
            onPressed: _parkReason != null && _followUpDate != null ? _submitPark : null,
          ),
        ],
      ),
    );
  }
}
