import 'package:flutter/material.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';

/// Minimal IB-RM directory used by the Assignment sheet. Mock-only: in
/// production this is a query against the IB-team user pool.
class IbRmOption {
  final String id;
  final String name;
  final String email;
  const IbRmOption(this.id, this.name, this.email);
}

const _mockIbRms = <IbRmOption>[
  IbRmOption('IBRM_SONIA', 'Sonia Parekh', 'sonia.parekh@jmfs.in'),
  IbRmOption('IBRM_SURAJ', 'Suraj Menon', 'suraj.menon@jmfs.in'),
  IbRmOption('IBRM_ADIT', 'Aditya Bose', 'aditya.bose@jmfs.in'),
  IbRmOption('IBRM_RIYA', 'Riya Tandon', 'riya.tandon@jmfs.in'),
];

/// CC list defaults per IB deal type. Editable per-lead in the sheet.
Map<IbDealType, List<String>> _defaultCcByDealType = const {
  IbDealType.ecm: ['ecm-desk@jmfs.in', 'head.ib@jmfs.in'],
  IbDealType.ma: ['ma-team@jmfs.in', 'head.ib@jmfs.in', 'legal@jmfs.in'],
  IbDealType.privateEquity: ['pe-coverage@jmfs.in', 'head.ib@jmfs.in'],
  IbDealType.structuredFinance: ['structured@jmfs.in', 'head.ib@jmfs.in'],
  IbDealType.ipo: ['ipo-desk@jmfs.in', 'head.ib@jmfs.in'],
  IbDealType.other: ['head.ib@jmfs.in'],
};

class AssignmentResult {
  final IbRmOption ibRm;
  final List<String> ccList;
  const AssignmentResult({required this.ibRm, required this.ccList});
}

Future<AssignmentResult?> showMisAssignmentSheet(
  BuildContext context, {
  required IbDealType dealType,
  required String companyLabel,
}) {
  return showModalBottomSheet<AssignmentResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MisAssignmentSheet(
      dealType: dealType,
      companyLabel: companyLabel,
    ),
  );
}

class _MisAssignmentSheet extends StatefulWidget {
  final IbDealType dealType;
  final String companyLabel;
  const _MisAssignmentSheet({
    required this.dealType,
    required this.companyLabel,
  });

  @override
  State<_MisAssignmentSheet> createState() => _MisAssignmentSheetState();
}

class _MisAssignmentSheetState extends State<_MisAssignmentSheet> {
  IbRmOption? _pick;
  late List<String> _cc;
  final _ccCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cc = [...?_defaultCcByDealType[widget.dealType]];
  }

  @override
  void dispose() {
    _ccCtrl.dispose();
    super.dispose();
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
                      'Approve & Assign IB RM',
                      style: AppTextStyles.heading3
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lead: ${widget.companyLabel} · ${widget.dealType.label}',
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
                      Text('Assign to',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Column(
                        children: _mockIbRms
                            .map((rm) => _ibRmRow(rm))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Email CC (auto-populated by deal type — editable)',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _cc
                            .map((e) => Chip(
                                  label: Text(e,
                                      style: AppTextStyles.caption),
                                  onDeleted: () =>
                                      setState(() => _cc.remove(e)),
                                  backgroundColor: AppColors.surfaceTertiary,
                                  side: BorderSide(
                                      color: AppColors.borderDefault),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ccCtrl,
                              decoration: InputDecoration(
                                hintText: 'add@email.com',
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
                                      color: AppColors.navyPrimary,
                                      width: 1.5),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              onSubmitted: _addCc,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CompassButton(
                            label: 'Add',
                            variant: CompassButtonVariant.secondary,
                            isFullWidth: false,
                            onPressed: () => _addCc(_ccCtrl.text),
                          ),
                        ],
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
                        label: 'Next: Review email',
                        onPressed: _pick == null
                            ? null
                            : () {
                                Navigator.of(context).pop(
                                  AssignmentResult(
                                      ibRm: _pick!, ccList: _cc),
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

  void _addCc(String raw) {
    final v = raw.trim();
    if (v.isEmpty || !v.contains('@')) return;
    setState(() {
      if (!_cc.contains(v)) _cc.add(v);
      _ccCtrl.clear();
    });
  }

  Widget _ibRmRow(IbRmOption rm) {
    final selected = _pick?.id == rm.id;
    return InkWell(
      onTap: () => setState(() => _pick = rm),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyPrimary.withValues(alpha: 0.06)
              : AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.navyPrimary
                : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                rm.name.split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rm.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(rm.email,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.navyPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}
