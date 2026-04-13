import 'package:flutter/material.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Bottom sheet for dropping a lead — reason is mandatory.
class DropLeadSheet extends StatefulWidget {
  final String leadName;
  final void Function(DropReason reason, String? notes) onDrop;

  const DropLeadSheet({
    super.key,
    required this.leadName,
    required this.onDrop,
  });

  static Future<void> show(
    BuildContext context, {
    required String leadName,
    required void Function(DropReason reason, String? notes) onDrop,
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

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

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
          'This lead will be marked as Dropped and visible to Admin/MIS for review.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 16),

        Text(
          'REASON (REQUIRED)',
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

        if (_reason == DropReason.other) ...[
          const SizedBox(height: 16),
          CompassTextField(
            controller: _notesCtrl,
            label: 'Specify reason',
            isRequired: true,
            maxLines: 2,
          ),
        ] else ...[
          const SizedBox(height: 16),
          CompassTextField(
            controller: _notesCtrl,
            label: 'Notes (optional)',
            maxLines: 2,
            maxLength: 300,
          ),
        ],
        const SizedBox(height: 20),

        CompassButton.danger(
          label: 'Drop this lead',
          icon: Icons.remove_circle_outline,
          onPressed: _reason != null &&
                  (_reason != DropReason.other ||
                      _notesCtrl.text.trim().isNotEmpty)
              ? () {
                  widget.onDrop(
                    _reason!,
                    _notesCtrl.text.trim().isEmpty
                        ? null
                        : _notesCtrl.text.trim(),
                  );
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
