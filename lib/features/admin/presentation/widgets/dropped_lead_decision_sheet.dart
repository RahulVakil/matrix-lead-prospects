import 'package:flutter/material.dart';
import '../../../../core/models/admin_action_record.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';

/// Admin decision for a dropped lead. Either Return to Pool or Keep as Dropped,
/// with a mandatory remark (>=10 chars, trimmed). Returns the record chosen,
/// or null if cancelled.
Future<AdminLeadAction?> showDroppedLeadDecisionSheet(
  BuildContext context,
  LeadModel lead, {
  required String adminId,
  required String adminName,
  required Future<void> Function(AdminActionRecord record) onDecision,
}) {
  return showModalBottomSheet<AdminLeadAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DecisionSheet(
      lead: lead,
      adminId: adminId,
      adminName: adminName,
      onDecision: onDecision,
    ),
  );
}

class _DecisionSheet extends StatefulWidget {
  final LeadModel lead;
  final String adminId;
  final String adminName;
  final Future<void> Function(AdminActionRecord record) onDecision;

  const _DecisionSheet({
    required this.lead,
    required this.adminId,
    required this.adminName,
    required this.onDecision,
  });

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  AdminLeadAction _action = AdminLeadAction.returnedToPool;
  final _remarksCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _remarksCtrl.text.trim().length >= 10;

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _error = 'Remarks must be at least 10 characters');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final record = AdminActionRecord(
      adminId: widget.adminId,
      adminName: widget.adminName,
      action: _action,
      remarks: _remarksCtrl.text.trim(),
      decidedAt: DateTime.now(),
    );
    try {
      await widget.onDecision(record);
      if (mounted) Navigator.of(context).pop(_action);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
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
                    const SizedBox(height: 14),
                    Text(
                      'Review dropped lead',
                      style: AppTextStyles.heading3
                          .copyWith(fontWeight: FontWeight.w700),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTertiary,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row('Lead', lead.fullName),
                            _row('Dropped by', lead.assignedRmName),
                            if (lead.droppedAt != null)
                              _row('Dropped on', _fmt(lead.droppedAt!)),
                            _row('Reason', lead.dropReason?.label ?? '—'),
                            if ((lead.dropNotes ?? '').isNotEmpty)
                              _row('RM notes', lead.dropNotes!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Decision',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      _decisionChoice(
                        value: AdminLeadAction.returnedToPool,
                        icon: Icons.replay,
                        color: AppColors.successGreen,
                        label: 'Return to Pool',
                        description:
                            'Lead goes back to shared pool for reassignment',
                      ),
                      const SizedBox(height: 6),
                      _decisionChoice(
                        value: AdminLeadAction.keptDropped,
                        icon: Icons.block,
                        color: AppColors.errorRed,
                        label: 'Keep as Dropped',
                        description:
                            'Do not return. RM\'s decision stands.',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Remarks (required, min 10 characters)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 3,
                        maxLength: 400,
                        onChanged: (_) {
                          // Re-evaluate _isValid on every keystroke so button
                          // enables as soon as ≥10 chars are typed.
                          setState(() {
                            if (_error != null) _error = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Explain why this lead should be returned or kept dropped…',
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
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CompassButton(
                        label: _action == AdminLeadAction.returnedToPool
                            ? 'Return to pool'
                            : 'Keep dropped',
                        isLoading: _submitting,
                        onPressed:
                            _isValid && !_submitting ? _submit : null,
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

  Widget _decisionChoice({
    required AdminLeadAction value,
    required IconData icon,
    required Color color,
    required String label,
    required String description,
  }) {
    final selected = _action == value;
    return InkWell(
      onTap: () => setState(() => _action = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.07)
              : AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
