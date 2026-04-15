import 'package:flutter/material.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/models/ib_progress_update.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';

Future<IbProgressUpdate?> showProgressUpdateSheet(
  BuildContext context, {
  required String authorId,
  required String authorName,
  IbProgressStatus? currentStatus,
}) {
  return showModalBottomSheet<IbProgressUpdate>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ProgressUpdateSheet(
      authorId: authorId,
      authorName: authorName,
      currentStatus: currentStatus,
    ),
  );
}

class _ProgressUpdateSheet extends StatefulWidget {
  final String authorId;
  final String authorName;
  final IbProgressStatus? currentStatus;
  const _ProgressUpdateSheet({
    required this.authorId,
    required this.authorName,
    required this.currentStatus,
  });

  @override
  State<_ProgressUpdateSheet> createState() => _ProgressUpdateSheetState();
}

class _ProgressUpdateSheetState extends State<_ProgressUpdateSheet> {
  late IbProgressStatus? _status;
  final _notesCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _status != null && _notesCtrl.text.trim().length >= 10;

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
                    const SizedBox(height: 12),
                    Text(
                      'Update lead status',
                      style: AppTextStyles.heading3
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '30-day cycle · pick the current stage and add a short note',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: IbProgressStatus.values
                            .map((s) => CompassChoiceChip<IbProgressStatus>(
                                  value: s,
                                  groupValue: _status,
                                  label: s.label,
                                  onSelected: (v) =>
                                      setState(() => _status = v),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Notes (required, min 10 characters)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        maxLength: 400,
                        onChanged: (_) {
                          if (_error != null) {
                            setState(() => _error = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Brief update on where the conversation is today…',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.surfaceTertiary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.navyPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.errorRed),
                        ),
                      ],
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
                        label: 'Save update',
                        onPressed: _isValid
                            ? () {
                                Navigator.of(context).pop(
                                  IbProgressUpdate(
                                    id: 'IBP_${DateTime.now().microsecondsSinceEpoch}',
                                    status: _status!,
                                    notes: _notesCtrl.text.trim(),
                                    authorId: widget.authorId,
                                    authorName: widget.authorName,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                              }
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
