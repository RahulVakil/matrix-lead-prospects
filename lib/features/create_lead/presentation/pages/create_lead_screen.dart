import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/consent_type.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/consent_record.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/coverage_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../coverage/presentation/widgets/coverage_result_sheet.dart';

/// Wealth lead capture: name, mobile, source, products. Coverage check fires
/// on phone blur AND on company-name input (debounced). All four de-dupe
/// scenarios (clear, existingClient, duplicateLead, requiresReview) are wired.
class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  static const _products = ['MF', 'PMS', 'AIF', 'Equity', 'Bonds', 'Insurance'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneFocus = FocusNode();
  Timer? _companyDebounce;

  LeadSource? _source;
  final Set<String> _productSet = {};
  bool _saving = false;
  bool _checkingCoverage = false;
  CoverageCheckResult? _coverage;
  bool _consentGranted = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onPhoneFocusChange);
  }

  @override
  void dispose() {
    _companyDebounce?.cancel();
    _phoneFocus.removeListener(_onPhoneFocusChange);
    _phoneFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // ── Coverage check triggers ────────────────────────────────────────

  Future<void> _runCoverageCheck() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final company = _companyController.text.trim();
    if (phone.isEmpty && name.isEmpty && company.isEmpty) return;

    setState(() => _checkingCoverage = true);
    final result = await getIt<CoverageRepository>().checkCoverage(
      phone: phone.isEmpty ? null : phone,
      name: name.isEmpty ? null : name,
      company: company.isEmpty ? null : company,
    );
    if (!mounted) return;
    setState(() {
      _coverage = result;
      _checkingCoverage = false;
    });

    if (result.canProceed) return;
    await _showCoverageSheet(result);
  }

  Future<void> _showCoverageSheet(CoverageCheckResult result) async {
    final decision = await showCoverageResultSheet(context, result);
    if (!mounted || decision == null) return;
    switch (decision) {
      case CoverageDecision.cancel:
        showCompassSnack(context, message: 'Capture cancelled');
        context.pop();
        break;
      case CoverageDecision.requestReassignment:
        showCompassSnack(
          context,
          message: 'Reassignment requested',
          type: CompassSnackType.warn,
        );
        context.pop();
        break;
      case CoverageDecision.saveAnyway:
      case CoverageDecision.proceed:
        // Stay on form. The user proceeds with capture.
        break;
    }
  }

  void _onPhoneFocusChange() {
    if (_phoneFocus.hasFocus) return;
    if (_phoneController.text.trim().length >= 10) {
      _runCoverageCheck();
    }
  }

  void _onCompanyChanged(String _) {
    _companyDebounce?.cancel();
    if (_companyController.text.trim().length < 3) return;
    _companyDebounce = Timer(const Duration(milliseconds: 500), _runCoverageCheck);
  }

  // ── Save logic ─────────────────────────────────────────────────────

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10 &&
      _source != null &&
      _productSet.isNotEmpty &&
      _consentGranted &&
      (_coverage?.status != CoverageStatus.existingClient);

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_source == null || _productSet.isEmpty) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final leadId = 'LEAD_${now.millisecondsSinceEpoch}';
    final consentRecord = ConsentRecord(
      id: 'CON_${now.millisecondsSinceEpoch}',
      leadId: leadId,
      consentType: DataConsentType.leadCapture,
      grantedAt: now,
      grantedByUserId: user.id,
      grantedByUserName: user.name,
      purposeStatement: DataConsentType.leadCapture.purposeStatement,
    );
    final lead = LeadModel(
      id: leadId,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      companyName: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      groupName: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      source: _source!,
      stage: LeadStage.lead,
      score: _source!.baseScore,
      productInterest: _productSet.toList(),
      assignedRmId: user.id,
      assignedRmName: user.name,
      createdAt: now,
      updatedAt: now,
      consentStatus: ConsentStatus.granted,
      consentRecords: [consentRecord],
    );

    await getIt<LeadRepository>().createLead(lead);
    if (!mounted) return;
    setState(() => _saving = false);
    showCompassSnack(context, message: 'Lead added', type: CompassSnackType.success);
    context.pushReplacement(RouteNames.leadDetailPath(leadId));
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      header: HeroAppBar.simple(title: 'New lead'),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CompassButton(
            label: 'Save Lead',
            isLoading: _saving,
            onPressed: _canSave ? _save : null,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            CompassTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'e.g. Rajesh Mehta',
              isRequired: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CompassTextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              label: 'Mobile',
              hint: '10-digit number',
              isRequired: true,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  v == null || v.trim().length < 10 ? 'Enter 10 digits' : null,
            ),
            const SizedBox(height: 8),
            _CoverageStatusBadge(
              checking: _checkingCoverage,
              result: _coverage,
              onTap: _coverage != null && !_coverage!.canProceed
                  ? () => _showCoverageSheet(_coverage!)
                  : null,
            ),
            const SizedBox(height: 16),
            CompassTextField(
              controller: _companyController,
              label: 'Company / Group',
              hint: 'Optional — auto-checks coverage',
              prefixIcon: Icons.apartment_outlined,
              onChanged: _onCompanyChanged,
            ),
            const SizedBox(height: 24),

            const CompassSectionHeader(title: 'Source'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LeadSource.values
                  .map(
                    (s) => CompassChoiceChip<LeadSource>(
                      value: s,
                      groupValue: _source,
                      label: s.label,
                      onSelected: (v) => setState(() => _source = v),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            const CompassSectionHeader(title: 'Product Interest'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _products
                  .map(
                    (p) => CompassFilterChip(
                      selected: _productSet.contains(p),
                      label: p,
                      onTap: () => setState(() {
                        if (_productSet.contains(p)) {
                          _productSet.remove(p);
                        } else {
                          _productSet.add(p);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // DPDP consent
            GestureDetector(
              onTap: () => setState(() => _consentGranted = !_consentGranted),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _consentGranted
                        ? AppColors.successGreen.withValues(alpha: 0.5)
                        : AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGranted,
                      activeColor: AppColors.navyPrimary,
                      onChanged: (v) => setState(() => _consentGranted = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data consent (DPDP Act)',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DataConsentType.leadCapture.purposeStatement,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Inline coverage status badge (below phone field)
// ────────────────────────────────────────────────────────────────────

class _CoverageStatusBadge extends StatelessWidget {
  final bool checking;
  final CoverageCheckResult? result;
  final VoidCallback? onTap;

  const _CoverageStatusBadge({
    required this.checking,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 8),
            Text('Checking coverage…',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ],
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();

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
      CoverageStatus.clear => 'Coverage clear',
      CoverageStatus.existingClient =>
        'Already a client of ${result!.existingRmName ?? "another RM"}',
      CoverageStatus.duplicateLead =>
        'Duplicate lead with ${result!.existingRmName ?? "another RM"}',
      CoverageStatus.requiresReview =>
        '${result!.alternateMatches.length} possible matches',
      CoverageStatus.dnd => 'Do not disturb',
    };

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) return Padding(padding: const EdgeInsets.only(left: 4), child: body);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(onTap: onTap, child: body),
    );
  }
}
