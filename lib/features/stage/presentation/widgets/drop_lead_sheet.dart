import 'package:flutter/material.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Bottom sheet for dropping a lead.
/// Per the demo-ready spec: notes are mandatory (≥10 chars); reason is now
/// optional. RM may pick a reason chip for analytics, but a meaningful
/// remark is what the dropped-leads tab shows.
class DropLeadSheet extends StatefulWidget {
  final String leadName;
  final void Function(DropReason? reason, String notes) onDrop;

  const DropLeadSheet({
    super.key,
    required this.leadName,
    required this.onDrop,
  });

  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required void Function(DropReason? reason, String notes) onDrop,
  }) {
    return showCompassSheet(
      context,
      title: 'Drop lead',
      isDismissible: false,
      child: DropLeadSheet(leadName: leadName, onDrop: onDrop),
    );
  }

  @override
  State<DropLeadSheet> createState() => _DropLeadSheetState();
}

class _DropLeadSheetState extends State<DropLeadSheet> {
  DropReason? _reason;
  final _notesCtrl = TextEditingController();
  static const int _minNotesLength = 10;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canDrop => _notesCtrl.text.trim().length >= _minNotesLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.leadName,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'This lead will be marked as Dropped. Notes are mandatory; the reason is optional.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'REASON (OPTIONAL)',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DropReason.values.map((r) {
            return CompassChoiceChip<DropReason>(
              value: r,
              groupValue: _reason,
              label: r.label,
              color: AppColors.errorRed,
              onSelected: (v) => setState(() => _reason = v),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        CompassTextField(
          controller: _notesCtrl,
          label: 'Notes (required, min $_minNotesLength chars)',
          isRequired: true,
          maxLines: 3,
          maxLength: 400,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        CompassButton.danger(
          label: 'Drop this lead',
          icon: Icons.remove_circle_outline,
          onPressed: _canDrop
              ? () {
                  widget.onDrop(_reason, _notesCtrl.text.trim());
                  Navigator.pop(context);
                }
              : null,
        ),
        const SizedBox(height: 10),
        CompassButton.tertiary(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
