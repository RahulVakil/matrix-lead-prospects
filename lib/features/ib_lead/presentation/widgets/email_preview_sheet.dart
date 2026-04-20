import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';

/// Draft email content returned when the Admin confirms the preview.
class EmailPreviewResult {
  final String subject;
  final String body;
  const EmailPreviewResult({required this.subject, required this.body});
}

/// Step 2 of the IB approval flow. Shows the outbound email to the assigned
/// IB SPOC as editable subject + body fields, with To / CC chips as a
/// read-only header. The Admin must review and click "Approve & Send" before
/// anything is persisted or any notifications fire.
Future<EmailPreviewResult?> showEmailPreviewSheet(
  BuildContext context, {
  required String toLabel,
  required List<String> ccList,
  required String initialSubject,
  required String initialBody,
}) {
  return showModalBottomSheet<EmailPreviewResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EmailPreviewSheet(
      toLabel: toLabel,
      ccList: ccList,
      initialSubject: initialSubject,
      initialBody: initialBody,
    ),
  );
}

class _EmailPreviewSheet extends StatefulWidget {
  final String toLabel;
  final List<String> ccList;
  final String initialSubject;
  final String initialBody;

  const _EmailPreviewSheet({
    required this.toLabel,
    required this.ccList,
    required this.initialSubject,
    required this.initialBody,
  });

  @override
  State<_EmailPreviewSheet> createState() => _EmailPreviewSheetState();
}

class _EmailPreviewSheetState extends State<_EmailPreviewSheet> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.initialSubject);
    _bodyCtrl = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _subjectCtrl.text.trim().isNotEmpty && _bodyCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderDefault,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Review email before sending',
                      style: AppTextStyles.heading3
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edit as needed. Nothing is sent until you tap Approve & Send.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddressRow(label: 'To', values: [widget.toLabel]),
                      if (widget.ccList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _AddressRow(label: 'CC', values: widget.ccList),
                      ],
                      const SizedBox(height: 14),
                      Text('Subject',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subjectCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 14),
                      Text('Body',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bodyCtrl,
                        onChanged: (_) => setState(() {}),
                        minLines: 8,
                        maxLines: 16,
                        decoration: _fieldDecoration(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CompassButton(
                        label: 'Cancel',
                        variant: CompassButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CompassButton(
                        label: 'Approve & Send',
                        icon: Icons.send,
                        onPressed: !_canSend
                            ? null
                            : () {
                                Navigator.of(context).pop(
                                  EmailPreviewResult(
                                    subject: _subjectCtrl.text.trim(),
                                    body: _bodyCtrl.text.trim(),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.navyPrimary, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

class _AddressRow extends StatelessWidget {
  final String label;
  final List<String> values;
  const _AddressRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map((v) => Chip(
                      label: Text(v, style: AppTextStyles.caption),
                      backgroundColor: AppColors.surfaceTertiary,
                      side: BorderSide(color: AppColors.borderDefault),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
