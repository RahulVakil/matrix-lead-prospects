import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/models/ib_progress_update.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_dropdown.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../../core/widgets/key_contacts_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../coverage/presentation/widgets/coverage_result_sheet.dart';
import '../../notifier/providers.dart';

/// IB Lead Capture form. Single scrollable screen, Riverpod-driven.
class IbLeadCaptureScreen extends StatelessWidget {
  final String? clientName;
  final String? clientCode;
  final String? companyName;
  final String? parentLeadId;
  final String? seedNotes;

  const IbLeadCaptureScreen({
    super.key,
    this.clientName,
    this.clientCode,
    this.companyName,
    this.parentLeadId,
    this.seedNotes,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final seed = IbLeadFormSeed(
      createdById: user.id,
      createdByName: user.name,
      clientName: clientName,
      clientCode: clientCode,
      companyName: companyName,
      notes: seedNotes,
    );

    return _CaptureBody(seed: seed, parentLeadId: parentLeadId);
  }
}

class _CaptureBody extends ConsumerWidget {
  final IbLeadFormSeed seed;
  final String? parentLeadId;
  const _CaptureBody({required this.seed, this.parentLeadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ibLeadFormProvider(seed));
    final notifier = ref.read(ibLeadFormProvider(seed).notifier);

    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'New IB lead',
        subtitle: 'Goes to Admin / MIS for review',
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CompassButton(
            label: 'Create IB Lead',
            isLoading: state.isSubmitting,
            onPressed: state.isReadyToSubmit
                ? () async {
                    final saved = await notifier.submit();
                    if (saved != null && context.mounted) {
                      // Update parent lead's ibLeadIds if converting from a wealth lead
                      if (parentLeadId != null) {
                        try {
                          final repo = getIt<LeadRepository>();
                          final parent = await repo.getLeadById(parentLeadId!);
                          await repo.updateLead(parent.copyWith(
                            ibLeadIds: [...parent.ibLeadIds, saved.id],
                            ibConvertedAt: DateTime.now(),
                          ));
                        } catch (_) {}
                      }
                      showCompassSnack(
                        context,
                        message:
                            'IB lead created — under Admin / MIS review',
                        type: CompassSnackType.success,
                      );
                      context.pop();
                    }
                  }
                : null,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const CompassSectionHeader(title: 'Client & Company'),
          const SizedBox(height: 12),
          if (state.clientName != null && state.clientName!.isNotEmpty)
            CompassTextField(
              label: 'Client',
              initialValue: state.clientName,
              readOnly: true,
              prefixIcon: Icons.person_outline,
            ),
          if (state.clientCode != null && state.clientCode!.isNotEmpty) ...[
            const SizedBox(height: 12),
            CompassTextField(
              label: 'Client Code',
              initialValue: state.clientCode,
              readOnly: true,
            ),
          ],
          const SizedBox(height: 12),
          CompassTextField(
            label: 'Company / Entity',
            isRequired: true,
            initialValue: state.companyName,
            hint: 'e.g. Mehta Industries Pvt Ltd',
            onChanged: notifier.setCompanyName,
          ),
          const SizedBox(height: 10),
          _IbCoverageRow(
            checking: state.isCheckingCoverage,
            result: state.lastCoverageResult,
            canRun: state.companyName.trim().isNotEmpty ||
                (state.clientName?.trim().isNotEmpty ?? false),
            onRun: notifier.runCoverageCheck,
          ),
          const SizedBox(height: 16),
          KeyContactsField(
            label: 'Key contacts',
            contacts: state.contacts,
            onChanged: notifier.setContacts,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Company Details'),
          const SizedBox(height: 12),
          Text('Industry', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          CompassDropdown<IbIndustry>(
            label: 'Industry / sector',
            value: state.industry,
            hint: 'Select an industry',
            items: IbIndustry.values
                .map((i) => CompassDropdownItem(value: i, label: i.label))
                .toList(),
            onChanged: notifier.setIndustry,
          ),
          if (state.industry == IbIndustry.other) ...[
            const SizedBox(height: 10),
            CompassTextField(
              label: 'Specify industry',
              isRequired: true,
              initialValue: state.industryOther,
              onChanged: notifier.setIndustryOther,
            ),
          ],
          const SizedBox(height: 12),
          CompassTextField(
            label: 'Website URL',
            hint: 'https://example.com',
            initialValue: state.websiteUrl,
            prefixIcon: Icons.link,
            onChanged: notifier.setWebsiteUrl,
          ),
          const SizedBox(height: 16),
          _CompanyFinancialField(
            docs: state.financialDocs,
            onAdd: notifier.addFinancialDoc,
            onRemove: notifier.removeFinancialDoc,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Deal Details'),
          const SizedBox(height: 12),
          Text('Type of deal *', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IbDealType.values
                .map(
                  (d) => CompassChoiceChip<IbDealType>(
                    value: d,
                    groupValue: state.dealType,
                    label: d.label,
                    onSelected: notifier.setDealType,
                  ),
                )
                .toList(),
          ),
          if (state.dealType == IbDealType.other) ...[
            const SizedBox(height: 12),
            CompassTextField(
              label: 'Specify deal type',
              isRequired: true,
              initialValue: state.dealTypeOtherText,
              onChanged: notifier.setDealTypeOtherText,
            ),
          ],
          const SizedBox(height: 16),
          _DealValueField(
            valueRupees: state.dealValue,
            onChange: notifier.setDealValue,
          ),

          const SizedBox(height: 16),
          Text('Deal stage', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IbDealStage.values
                .map(
                  (s) => CompassChoiceChip<IbDealStage>(
                    value: s,
                    groupValue: state.dealStage,
                    label: s.label,
                    onSelected: notifier.setDealStage,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _TimelineSlider(
            months: state.timelineMonths,
            onChanged: notifier.setTimelineMonths,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Context'),
          const SizedBox(height: 8),
          Text('How was this identified?', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IbIdentifiedHow.values
                .map(
                  (h) => CompassFilterChip(
                    selected: state.identifiedHow.contains(h),
                    label: h.label,
                    onTap: () => notifier.toggleIdentifiedHow(h),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          CompassTextField(
            label: 'Notes',
            hint: 'Brief context, sector, parties involved…',
            initialValue: state.notes,
            maxLines: 4,
            maxLength: 500,
            onChanged: notifier.setNotes,
          ),
          const SizedBox(height: 16),
          _ConfidentialBlock(
            isConfidential: state.isConfidential,
            reason: state.confidentialReason,
            onToggle: notifier.setConfidential,
            onReasonChanged: notifier.setConfidentialReason,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Declaration'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => notifier.setDeclaration(!state.declarationAccepted),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: state.declarationAccepted,
                    activeColor: AppColors.navyPrimary,
                    onChanged: (v) => notifier.setDeclaration(v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'I confirm this lead is based on a genuine conversation '
                      'and the information provided is accurate to the best of '
                      'my knowledge.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (state.submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              state.submitError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Inline coverage check row for IB — optional to run, never blocks submit
// ────────────────────────────────────────────────────────────────────

class _IbCoverageRow extends StatelessWidget {
  final bool checking;
  final CoverageCheckResult? result;
  final bool canRun;
  final Future<void> Function() onRun;

  const _IbCoverageRow({
    required this.checking,
    required this.result,
    required this.canRun,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking coverage…',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    if (result == null) {
      // No result yet → show the trigger button
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: canRun ? () => onRun() : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: canRun
                  ? AppColors.navyPrimary.withValues(alpha: 0.08)
                  : AppColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canRun
                    ? AppColors.navyPrimary.withValues(alpha: 0.3)
                    : AppColors.borderDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: canRun ? AppColors.navyPrimary : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Check coverage (optional)',
                  style: AppTextStyles.caption.copyWith(
                    color: canRun ? AppColors.navyPrimary : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Result loaded → show inline status pill with link to read-only sheet
    final color = switch (result!.status) {
      CoverageStatus.clear => AppColors.successGreen,
      CoverageStatus.existingClient => AppColors.errorRed,
      CoverageStatus.duplicateLead => AppColors.warmAmber,
      CoverageStatus.requiresReview => AppColors.tealAccent,
      CoverageStatus.dnd => AppColors.errorRed,
    };
    final icon = switch (result!.status) {
      CoverageStatus.clear => Icons.check_circle_outline,
      CoverageStatus.existingClient => Icons.shield,
      CoverageStatus.duplicateLead => Icons.warning_amber_rounded,
      CoverageStatus.requiresReview => Icons.search,
      CoverageStatus.dnd => Icons.do_not_disturb_on_outlined,
    };
    final label = switch (result!.status) {
      CoverageStatus.clear => 'No existing coverage',
      CoverageStatus.existingClient =>
        'Already a client of ${result!.existingRmName ?? "another RM"}',
      CoverageStatus.duplicateLead =>
        'Duplicate lead with ${result!.existingRmName ?? "another RM"}',
      CoverageStatus.requiresReview =>
        '${result!.alternateMatches.length} possible matches',
      CoverageStatus.dnd => 'Do not disturb',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (result!.status != CoverageStatus.clear)
            TextButton(
              onPressed: () => showCoverageResultSheet(
                context,
                result!,
                readOnly: true,
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: color,
              ),
              child: const Text('Details'),
            ),
          IconButton(
            tooltip: 'Re-run',
            icon: Icon(Icons.refresh, size: 16, color: color),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: () => onRun(),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Timeline slider — 2-month increments, Now → 24 months (last = "1Y+")
// ────────────────────────────────────────────────────────────────────

String _timelineLabel(int months) {
  if (months == 0) return 'Now';
  if (months >= 24) return '1 Year +';
  if (months == 12) return '1 Year';
  if (months > 12) {
    final extra = months - 12;
    return '1 Year $extra M';
  }
  return '$months months';
}

class _TimelineSlider extends StatelessWidget {
  final int? months;
  final ValueChanged<int> onChanged;

  const _TimelineSlider({required this.months, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = months ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Timeline', style: AppTextStyles.labelSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                months == null ? 'Not set' : _timelineLabel(current),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.navyPrimary,
            inactiveTrackColor: AppColors.borderDefault,
            thumbColor: AppColors.navyPrimary,
            overlayColor: AppColors.navyPrimary.withValues(alpha: 0.12),
            valueIndicatorColor: AppColors.navyPrimary,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            trackHeight: 4,
          ),
          child: Slider(
            min: 0,
            max: 24,
            divisions: 12,
            value: current.toDouble().clamp(0, 24),
            label: _timelineLabel(current),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Now',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 10)),
              Text('6M',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 10)),
              Text('1Y',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 10)),
              Text('18M',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 10)),
              Text('1Y+',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Deal Value field — 3 chips that pre-fill a manual entry field
// ────────────────────────────────────────────────────────────────────

class _DealValueField extends StatefulWidget {
  /// Stored value in INR (rupees). Capture form deals in Cr for input.
  final double? valueRupees;
  final ValueChanged<double?> onChange;
  const _DealValueField({required this.valueRupees, required this.onChange});

  @override
  State<_DealValueField> createState() => _DealValueFieldState();
}

class _DealValueFieldState extends State<_DealValueField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _toCrText(widget.valueRupees));
  }

  @override
  void didUpdateWidget(covariant _DealValueField old) {
    super.didUpdateWidget(old);
    final newText = _toCrText(widget.valueRupees);
    if (newText != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _toCrText(double? rupees) {
    if (rupees == null) return '';
    final cr = rupees / 1e7;
    if (cr == cr.roundToDouble()) return cr.toStringAsFixed(0);
    return cr.toStringAsFixed(2);
  }

  IbDealSizeBucket? _activeBucket() {
    if (widget.valueRupees == null) return null;
    return IbDealSizeBucket.fromCr(widget.valueRupees! / 1e7);
  }

  bool get _showHighWarning {
    final v = widget.valueRupees;
    return v != null && (v / 1e7) > 5000;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeBucket();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Potential deal value *', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IbDealSizeBucket.values
              .map(
                (b) => CompassChoiceChip<IbDealSizeBucket>(
                  value: b,
                  groupValue: active,
                  label: b.label,
                  onSelected: (bucket) {
                    final cr = bucket.prefillCr;
                    widget.onChange(cr * 1e7);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Or enter exact deal value (₹ Cr)',
                  hintText: 'e.g. 250',
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
                    borderSide: const BorderSide(
                        color: AppColors.navyPrimary, width: 1.5),
                  ),
                ),
                onChanged: (v) {
                  final raw = v.trim();
                  if (raw.isEmpty) {
                    widget.onChange(null);
                    return;
                  }
                  final cr = double.tryParse(raw);
                  if (cr == null || cr < 0) return;
                  widget.onChange(cr * 1e7);
                },
              ),
            ),
          ],
        ),
        if (_showHighWarning) ...[
          const SizedBox(height: 6),
          Text(
            'Note: ₹5,000 Cr+ — please double-check the figure.',
            style: AppTextStyles.caption.copyWith(color: AppColors.warmAmber),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Company Financial — multi-file uploader (mocked storage)
// PDF / XLSX / DOCX / images, max 5 files, 10 MB each (validation TODO).
// ────────────────────────────────────────────────────────────────────

class _CompanyFinancialField extends StatelessWidget {
  final List<IbFinancialDoc> docs;
  final ValueChanged<IbFinancialDoc> onAdd;
  final ValueChanged<String> onRemove;

  const _CompanyFinancialField({
    required this.docs,
    required this.onAdd,
    required this.onRemove,
  });

  static const _allowed = ['PDF', 'XLSX', 'DOCX', 'JPG', 'PNG'];

  Future<void> _pickMock(BuildContext context) async {
    if (docs.length >= 5) {
      showCompassSnack(context,
          message: 'Max 5 files', type: CompassSnackType.warn);
      return;
    }
    // Mocked picker: prototype only. In production wire to file_picker package
    // and stream to backend storage (e.g. Supabase / S3).
    final sampleNames = [
      'Annual_Report_FY24.pdf',
      'Financial_Summary_FY24.xlsx',
      'Investor_Deck.pdf',
      'Audited_Statements.pdf',
      'Cap_Table.xlsx',
    ];
    final next = sampleNames[docs.length % sampleNames.length];
    final ext = next.split('.').last.toUpperCase();
    final mime = ext == 'PDF'
        ? 'application/pdf'
        : ext == 'XLSX'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : ext == 'DOCX'
                ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                : 'image/jpeg';
    onAdd(IbFinancialDoc(
      id: 'DOC_${DateTime.now().microsecondsSinceEpoch}',
      fileName: next,
      mimeType: mime,
      sizeBytes: 380000 + docs.length * 14000,
      uploadedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Financial', style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        Text(
          'Attach annual report, audited statements, financial summary etc. '
          '${_allowed.join(' / ')} • Max 5 files • 10 MB each',
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        if (docs.isEmpty)
          GestureDetector(
            onTap: () => _pickMock(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surfaceTertiary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderDefault,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.navyPrimary),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add file',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.navyPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...docs.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        size: 18, color: AppColors.navyPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.fileName,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            d.sizeLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Remove',
                      onPressed: () => onRemove(d.id),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (docs.length < 5)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickMock(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add another file'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navyPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Confidential block — toggle + reason + explanation of what it restricts
// ────────────────────────────────────────────────────────────────────

class _ConfidentialBlock extends StatelessWidget {
  final bool isConfidential;
  final String reason;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onReasonChanged;

  const _ConfidentialBlock({
    required this.isConfidential,
    required this.reason,
    required this.onToggle,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        color: isConfidential
            ? accent.withValues(alpha: 0.06)
            : AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfidential
              ? accent.withValues(alpha: 0.4)
              : AppColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfidential ? Icons.lock : Icons.lock_outline,
                size: 18,
                color: isConfidential ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mark as Confidential',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isConfidential ? accent : AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: isConfidential,
                activeThumbColor: accent,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hides company name + key contacts from the MIS / Sonia / Suraj '
            'review queue and the IB team until the lead is assigned. '
            'Identifying details remain visible to you and your Team Lead.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (isConfidential) ...[
            const SizedBox(height: 12),
            TextField(
              maxLines: 2,
              maxLength: 200,
              onChanged: onReasonChanged,
              controller: TextEditingController(text: reason)
                ..selection =
                    TextSelection.collapsed(offset: reason.length),
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Pre-IPO sensitivity, related-party concern…',
                filled: true,
                fillColor: AppColors.surfacePrimary,
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
                  borderSide:
                      BorderSide(color: accent.withValues(alpha: 0.6), width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
