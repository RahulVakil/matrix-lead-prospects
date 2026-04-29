import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';

/// RM-Assisted Onboarding form. Replaces the old "Advance Stage" CTA on
/// the Lead Detail screen. Single-page form with 4 sections:
///   1. Identity verification (PAN / Aadhar / DOB)
///   2. AUM commitment
///   3. Product interest (multi-select chips)
///   4. Signatures (two acknowledgement checkboxes)
///
/// On submit the lead is stamped with stage = LeadStage.onboard and a
/// structured one-liner is appended to lead.notes summarising the
/// captured fields. The form does not bloat LeadModel with onboarding
/// metadata — for the demo, the notes summary is the system of record.
class RmAssistedOnboardingScreen extends StatefulWidget {
  final String leadId;
  const RmAssistedOnboardingScreen({super.key, required this.leadId});

  @override
  State<RmAssistedOnboardingScreen> createState() =>
      _RmAssistedOnboardingScreenState();
}

class _RmAssistedOnboardingScreenState
    extends State<RmAssistedOnboardingScreen> {
  final _leadRepo = getIt<LeadRepository>();
  final _formKey = GlobalKey<FormState>();

  final _panCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _aumCtrl = TextEditingController();
  DateTime? _dob;

  // Reuses the existing product list used elsewhere in the app
  static const _products = [
    'Mutual Fund',
    'PMS',
    'AIF',
    'Equity',
    'Bonds',
    'Insurance',
    'Real Estate Fund',
    'Structured Products',
  ];
  final Set<String> _selectedProducts = {};

  bool _kycCollected = false;
  bool _formSigned = false;

  bool _loading = true;
  bool _saving = false;
  LeadModel? _lead;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _panCtrl.dispose();
    _aadharCtrl.dispose();
    _aumCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lead = await _leadRepo.getLeadById(widget.leadId);
    if (!mounted) return;
    setState(() {
      _lead = lead;
      _loading = false;
    });
  }

  bool get _canSubmit {
    if (_panCtrl.text.trim().length != 10) return false;
    final aadhar = _aadharCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (aadhar.length != 12) return false;
    if (_dob == null) return false;
    final aum = double.tryParse(_aumCtrl.text.trim());
    if (aum == null || aum <= 0) return false;
    if (_selectedProducts.isEmpty) return false;
    if (!_kycCollected || !_formSigned) return false;
    return true;
  }

  String _maskedAadhar() {
    final digits = _aadharCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return digits;
    return '****-****-${digits.substring(digits.length - 4)}';
  }

  String _maskedPan() {
    final v = _panCtrl.text.trim().toUpperCase();
    if (v.length < 4) return v;
    return '${v.substring(0, 3)}***${v.substring(v.length - 1)}';
  }

  String _aumDisplay() {
    final aum = double.tryParse(_aumCtrl.text.trim()) ?? 0;
    if (aum >= 10000000) return '₹${(aum / 10000000).toStringAsFixed(1)} Cr';
    if (aum >= 100000) return '₹${(aum / 100000).toStringAsFixed(1)} L';
    return '₹${aum.toStringAsFixed(0)}';
  }

  Future<void> _submit() async {
    if (!_canSubmit || _lead == null) return;
    setState(() => _saving = true);

    final summary = StringBuffer()
      ..writeln()
      ..write('Onboarded: PAN ${_maskedPan()}, Aadhar ${_maskedAadhar()}, '
          'DOB ${_dob!.day}/${_dob!.month}/${_dob!.year}, '
          'AUM ${_aumDisplay()}, Products ${_selectedProducts.join("/")} '
          '— ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');

    final updated = _lead!.copyWith(
      stage: LeadStage.onboard,
      notes: (_lead!.notes ?? '') + summary.toString(),
      updatedAt: DateTime.now(),
    );
    await _leadRepo.updateLead(updated);
    // Also call updateLeadStage so any timeline/audit hooks the repo runs
    // on stage transitions still fire. The mock impl is idempotent for
    // already-set stages.
    await _leadRepo.updateLeadStage(_lead!.id, LeadStage.onboard,
        notes: 'RM-assisted onboarding submitted');

    if (!mounted) return;
    setState(() => _saving = false);
    showCompassSnack(
      context,
      message: 'Lead onboarded — converted to client',
      type: CompassSnackType.success,
    );
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _lead == null) {
      return HeroScaffold(
        header: HeroAppBar.simple(title: 'Onboard lead'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final lead = _lead!;
    return HeroScaffold(
      header: HeroAppBar.simple(
        title: 'Onboard lead',
        subtitle: lead.fullName,
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CompassButton(
            label: 'Submit Onboarding',
            isLoading: _saving,
            icon: Icons.check_circle_outline,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            // ── Identity Verification ───────────────────────────
            const CompassSectionHeader(title: 'Identity verification'),
            const SizedBox(height: 10),
            CompassTextField(
              controller: _panCtrl,
              label: 'PAN',
              isRequired: true,
              hint: 'AAAAA1234A',
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                _UppercaseFormatter(),
              ],
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length != 10) return '10 chars required';
                final pattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                if (!pattern.hasMatch(s)) return 'Format: AAAAA1234A';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CompassTextField(
              controller: _aadharCtrl,
              label: 'Aadhar',
              isRequired: true,
              hint: '12-digit number',
              keyboardType: TextInputType.number,
              maxLength: 14, // accommodate '1234 5678 9012' formatting
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length != 12) return '12 digits required';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (_aadharCtrl.text.replaceAll(RegExp(r'\D'), '').length == 12) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Will be stored as ${_maskedAadhar()}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ??
                      DateTime.now().subtract(const Duration(days: 365 * 30)),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now()
                      .subtract(const Duration(days: 365 * 18)),
                );
                if (picked != null) setState(() => _dob = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dob == null
                            ? 'Date of birth (required)'
                            : 'DOB · ${_dob!.day}/${_dob!.month}/${_dob!.year}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _dob == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── AUM Commitment ──────────────────────────────────
            const CompassSectionHeader(title: 'AUM commitment'),
            const SizedBox(height: 10),
            CompassTextField(
              controller: _aumCtrl,
              label: 'Estimated AUM (₹)',
              isRequired: true,
              hint: 'e.g. 5000000 for ₹50 L',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (_aumCtrl.text.trim().isNotEmpty &&
                double.tryParse(_aumCtrl.text.trim()) != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Display: ${_aumDisplay()}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── Product Interest ────────────────────────────────
            const CompassSectionHeader(title: 'Product interest'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _products.map((p) {
                final selected = _selectedProducts.contains(p);
                return FilterChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedProducts.remove(p);
                    } else {
                      _selectedProducts.add(p);
                    }
                  }),
                  selectedColor:
                      AppColors.navyPrimary.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.navyPrimary,
                  side: BorderSide(
                    color: selected
                        ? AppColors.navyPrimary.withValues(alpha: 0.5)
                        : AppColors.borderDefault,
                  ),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: selected
                        ? AppColors.navyPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // ── Signatures ──────────────────────────────────────
            const CompassSectionHeader(title: 'Signatures'),
            const SizedBox(height: 10),
            _SigCheckRow(
              value: _kycCollected,
              label: 'Client KYC documents collected',
              onChanged: (v) => setState(() => _kycCollected = v ?? false),
            ),
            const SizedBox(height: 8),
            _SigCheckRow(
              value: _formSigned,
              label: 'Onboarding form signed by client',
              onChanged: (v) => setState(() => _formSigned = v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SigCheckRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _SigCheckRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? AppColors.successGreen.withValues(alpha: 0.5)
                : AppColors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.navyPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Forces uppercase as the user types — used for PAN entry.
class _UppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
