import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/update_type.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// One-tap status update — used from the Lead Inbox swipe action and the
/// Lead Detail overflow menu. Writes a `statusUpdate` entry into the merged
/// timeline and bumps the lead's latestStatus.
class QuickUpdateSheet extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String authorId;
  final String authorName;
  final VoidCallback? onSaved;

  const QuickUpdateSheet({
    super.key,
    required this.leadId,
    required this.leadName,
    required this.authorId,
    required this.authorName,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String leadId,
    required String leadName,
    required String authorId,
    required String authorName,
    VoidCallback? onSaved,
  }) {
    return showCompassSheet(
      context,
      title: 'Quick update',
      child: QuickUpdateSheet(
        leadId: leadId,
        leadName: leadName,
        authorId: authorId,
        authorName: authorName,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<QuickUpdateSheet> createState() => _QuickUpdateSheetState();
}

class _QuickUpdateSheetState extends State<QuickUpdateSheet> {
  LeadUpdateStatus? _status;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_status == null) return;
    setState(() => _saving = true);
    await getIt<LeadRepository>().addStatusUpdate(
      widget.leadId,
      status: _status!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      authorId: widget.authorId,
      authorName: widget.authorName,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadName, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        Text('Status', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LeadUpdateStatus.values
              .map(
                (s) => CompassChoiceChip<LeadUpdateStatus>(
                  value: s,
                  groupValue: _status,
                  label: s.label,
                  color: s.color,
                  onSelected: (v) => setState(() => _status = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        CompassTextField(
          controller: _notes,
          label: 'Notes',
          hint: 'One line of context (optional)',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        CompassButton(
          label: 'Save update',
          isLoading: _saving,
          onPressed: _status != null ? _save : null,
        ),
      ],
    );
  }
}
