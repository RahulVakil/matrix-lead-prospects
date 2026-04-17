import 'package:flutter/material.dart';
import '../../../../core/models/ib_progress_update.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';

/// Result returned by the resubmit sheet — the RM's reply text + any attached
/// documents they uploaded in response to the Admin/MIS remark.
class ResubmitResult {
  final String replyText;
  final List<IbFinancialDoc> docs;
  const ResubmitResult({required this.replyText, required this.docs});
}

Future<ResubmitResult?> showResubmitSheet(
  BuildContext context, {
  required String adminRemark,
}) {
  return showModalBottomSheet<ResubmitResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ResubmitSheetBody(adminRemark: adminRemark),
  );
}

class _ResubmitSheetBody extends StatefulWidget {
  final String adminRemark;
  const _ResubmitSheetBody({required this.adminRemark});

  @override
  State<_ResubmitSheetBody> createState() => _ResubmitSheetBodyState();
}

class _ResubmitSheetBodyState extends State<_ResubmitSheetBody> {
  final _replyCtrl = TextEditingController();
  final List<IbFinancialDoc> _docs = [];

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  // RM-1: Resolution must be at least 20 chars
  bool get _isValid => _replyCtrl.text.trim().length >= 20;

  void _addMockDoc() {
    if (_docs.length >= 3) return; // RM-1: max 3 supporting docs
    final samples = [
      'Response_Note.pdf',
      'Updated_Financials.xlsx',
      'Clarification_Doc.pdf',
      'Supporting_Evidence.pdf',
      'Amended_Term_Sheet.docx',
    ];
    final name = samples[_docs.length % samples.length];
    setState(() {
      _docs.add(IbFinancialDoc(
        id: 'RDOC_${DateTime.now().microsecondsSinceEpoch}',
        fileName: name,
        mimeType: name.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream',
        sizeBytes: 250000 + _docs.length * 12000,
        uploadedAt: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
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
                    const SizedBox(height: 14),
                    Text(
                      'Respond & Resubmit',
                      style: AppTextStyles.heading3
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address the Admin / MIS remark below, then resubmit.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show the admin remark being addressed
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.errorRed.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.report_gmailerrorred,
                                    size: 16, color: AppColors.errorRed),
                                const SizedBox(width: 6),
                                Text(
                                  'Admin / MIS remark',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.adminRemark,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your resolution (required, min 20 characters)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _replyCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              'Explain how you have addressed the concern...',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.surfaceTertiary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.navyPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Attach supporting documents (optional)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      if (_docs.isNotEmpty) ...[
                        ..._docs.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfacePrimary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.borderDefault),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.insert_drive_file_outlined,
                                      size: 18,
                                      color: AppColors.navyPrimary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(d.fileName,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                            overflow:
                                                TextOverflow.ellipsis),
                                        Text(d.sizeLabel,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color:
                                                        AppColors.textHint,
                                                    fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => setState(
                                        () => _docs.remove(d)),
                                    splashRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_docs.length < 3)
                        TextButton.icon(
                          onPressed: _addMockDoc,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: Text(
                            _docs.isEmpty
                                ? 'Add document'
                                : 'Add another',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.navyPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Bottom bar
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
                        label: 'Resubmit',
                        onPressed: _isValid
                            ? () => Navigator.of(context).pop(
                                  ResubmitResult(
                                    replyText: _replyCtrl.text.trim(),
                                    docs: List.unmodifiable(_docs),
                                  ),
                                )
                            : null,
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
}
