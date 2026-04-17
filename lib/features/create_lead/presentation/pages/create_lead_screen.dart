import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/consent_type.dart';
import '../../../../core/enums/lead_entity_type.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/consent_record.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/coverage_repository.dart';
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
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../coverage/presentation/widgets/coverage_result_sheet.dart';

/// Create Lead — full capture form with entity type, structured name,
/// family/group with inline coverage, expanded sources, connect-rep.
class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Entity type
  LeadEntityType _entityType = LeadEntityType.individual;
  LeadSubType? _subType;

  // Name fields
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController(); // non-individual
  final _familyGroupCtrl = TextEditingController();

  // Contact
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  // Source
  LeadSource? _source;

  // Connect rep
  bool _hasRequestedConnect = false;
  final _repNameCtrl = TextEditingController();
  final _repPhoneCtrl = TextEditingController();
  final _repEmailCtrl = TextEditingController();

  // State
  bool _saving = false;
  bool _checkingCoverage = false;
  CoverageCheckResult? _coverage;
  bool _consentGranted = false;
  Timer? _nameDebounce;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onPhoneBlur);
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _phoneFocus.removeListener(_onPhoneBlur);
    _phoneFocus.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _familyGroupCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _repNameCtrl.dispose();
    _repPhoneCtrl.dispose();
    _repEmailCtrl.dispose();
    super.dispose();
  }

  // ── Computed name ──────────────────────────────────────────────────

  String get _computedName {
    if (_entityType == LeadEntityType.nonIndividual) {
      return _fullNameCtrl.text.trim();
    }
    final parts = [
      _firstNameCtrl.text.trim(),
      _middleNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  // ── Coverage ──────────────────────────────────────────────────────

  void _onPhoneBlur() {
    if (_phoneFocus.hasFocus) return;
    if (_phoneCtrl.text.trim().length >= 10) _runCoverage();
  }

  void _onNameOrFamilyChanged(String _) {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 600), () {
      if (_computedName.length >= 3 || _familyGroupCtrl.text.trim().length >= 3) {
        _runCoverage();
      }
    });
  }

  Future<void> _runCoverage() async {
    final name = _computedName;
    final phone = _phoneCtrl.text.trim();
    final family = _familyGroupCtrl.text.trim();
    if (name.isEmpty && phone.isEmpty && family.isEmpty) return;

    setState(() => _checkingCoverage = true);
    final result = await getIt<CoverageRepository>().checkCoverage(
      name: name.isEmpty ? null : name,
      phone: phone.length >= 10 ? phone : null,
      company: family.isEmpty ? null : family,
      groupName: family.isEmpty ? null : family,
    );
    if (!mounted) return;
    setState(() {
      _coverage = result;
      _checkingCoverage = false;
    });
    if (!result.canProceed) {
      final decision = await showCoverageResultSheet(context, result);
      if (!mounted || decision == null) return;
      if (decision == CoverageDecision.cancel ||
          decision == CoverageDecision.requestReassignment) {
        if (mounted) {
          showCompassSnack(
            context,
            message: decision == CoverageDecision.requestReassignment
                ? 'Reassignment requested'
                : 'Cancelled',
          );
          context.pop();
        }
      }
    }
  }

  // ── Save ───────────────────────────────────────────────────────────

  /// Hard block (#7): both existingClient AND duplicateLead block submit.
  bool get _isDuplicate =>
      _coverage?.status == CoverageStatus.existingClient ||
      _coverage?.status == CoverageStatus.duplicateLead;

  bool get _canSave {
    final hasName = _computedName.isNotEmpty;
    final hasPhone = _phoneCtrl.text.trim().length >= 10;
    return hasName && hasPhone && _source != null && _consentGranted && !_isDuplicate;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_canSave) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final leadId = 'LEAD_${now.millisecondsSinceEpoch}';
    final consent = ConsentRecord(
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
      entityType: _entityType,
      subType: _entityType == LeadEntityType.nonIndividual ? _subType : null,
      fullName: _computedName,
      firstName: _entityType == LeadEntityType.individual
          ? _firstNameCtrl.text.trim()
          : null,
      middleName: _entityType == LeadEntityType.individual
          ? (_middleNameCtrl.text.trim().isEmpty
              ? null
              : _middleNameCtrl.text.trim())
          : null,
      lastName: _entityType == LeadEntityType.individual
          ? _lastNameCtrl.text.trim()
          : null,
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      groupName: _familyGroupCtrl.text.trim().isEmpty
          ? null
          : _familyGroupCtrl.text.trim(),
      companyName: _entityType == LeadEntityType.nonIndividual
          ? _fullNameCtrl.text.trim()
          : (_familyGroupCtrl.text.trim().isEmpty
              ? null
              : _familyGroupCtrl.text.trim()),
      source: _source!,
      stage: LeadStage.lead,
      score: _source!.baseScore,
      assignedRmId: user.id,
      assignedRmName: user.name,
      createdAt: now,
      updatedAt: now,
      consentStatus: ConsentStatus.granted,
      consentRecords: [consent],
      hasRequestedConnect: _hasRequestedConnect,
      connectRepName: _hasRequestedConnect ? _repNameCtrl.text.trim() : null,
      connectRepPhone: _hasRequestedConnect ? _repPhoneCtrl.text.trim() : null,
      connectRepEmail: _hasRequestedConnect ? _repEmailCtrl.text.trim() : null,
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDuplicate)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block,
                          size: 16, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicate found — this lead already exists. Contact your TL to proceed.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              CompassButton(
                label: 'Save Lead',
                isLoading: _saving,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            // ── Entity type toggle ──────────────────────────────
            const CompassSectionHeader(title: 'Lead type'),
            const SizedBox(height: 10),
            Row(
              children: LeadEntityType.values.map((t) {
                final selected = _entityType == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t == LeadEntityType.individual ? 5 : 0,
                      left: t == LeadEntityType.nonIndividual ? 5 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _entityType = t;
                        _coverage = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.navyPrimary
                              : AppColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.navyPrimary
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            t.label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Sub-type (Non-Individual only) ──────────────────
            if (_entityType == LeadEntityType.nonIndividual) ...[
              const SizedBox(height: 16),
              CompassDropdown<LeadSubType>(
                label: 'Entity sub-type',
                isRequired: true,
                value: _subType,
                hint: 'Select type',
                items: LeadSubType.values
                    .map((s) => CompassDropdownItem(value: s, label: s.label))
                    .toList(),
                onChanged: (v) => setState(() => _subType = v),
              ),
              // RM-3: free-text input when "Others" selected
              if (_subType == LeadSubType.other) ...[
                const SizedBox(height: 12),
                CompassTextField(
                  label: 'Specify Entity Sub Type',
                  isRequired: true,
                  hint: 'e.g. Section 8 Company',
                  maxLength: 100,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required when Others is selected' : null,
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ── Name fields ─────────────────────────────────────
            const CompassSectionHeader(title: 'Name'),
            const SizedBox(height: 10),
            if (_entityType == LeadEntityType.individual) ...[
              CompassTextField(
                controller: _firstNameCtrl,
                label: 'First name',
                isRequired: true,
                onChanged: _onNameOrFamilyChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _middleNameCtrl,
                label: 'Middle name',
                onChanged: _onNameOrFamilyChanged,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _lastNameCtrl,
                label: 'Last name',
                isRequired: true,
                onChanged: _onNameOrFamilyChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ] else ...[
              CompassTextField(
                controller: _fullNameCtrl,
                label: 'Full name / Entity name',
                isRequired: true,
                onChanged: _onNameOrFamilyChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 12),
            CompassTextField(
              controller: _familyGroupCtrl,
              label: 'Family / Group name',
              hint: 'Coverage check runs on this',
              prefixIcon: Icons.family_restroom_outlined,
              onChanged: _onNameOrFamilyChanged,
            ),
            const SizedBox(height: 8),
            _CoverageBadge(
              checking: _checkingCoverage,
              result: _coverage,
              onTap: _coverage != null && !_coverage!.canProceed
                  ? () => showCoverageResultSheet(context, _coverage!)
                  : null,
            ),

            const SizedBox(height: 20),

            // ── Contact ─────────────────────────────────────────
            const CompassSectionHeader(title: 'Contact'),
            const SizedBox(height: 10),
            CompassTextField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              label: 'Mobile number',
              isRequired: true,
              hint: 'Indian or international',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  v == null || v.trim().length < 10 ? '10+ digits' : null,
            ),
            const SizedBox(height: 12),
            CompassTextField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'Optional',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),

            const SizedBox(height: 20),

            // ── Source ───────────────────────────────────────────
            const CompassSectionHeader(title: 'Source'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LeadSource.values
                  .map((s) => CompassChoiceChip<LeadSource>(
                        value: s,
                        groupValue: _source,
                        label: s.label,
                        onSelected: (v) => setState(() => _source = v),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // ── Connect rep ─────────────────────────────────────
            const CompassSectionHeader(title: 'Connect request'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lead has requested to connect with a representative?',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                Switch(
                  value: _hasRequestedConnect,
                  activeColor: AppColors.navyPrimary,
                  onChanged: (v) => setState(() => _hasRequestedConnect = v),
                ),
              ],
            ),
            if (_hasRequestedConnect) ...[
              const SizedBox(height: 12),
              CompassTextField(
                controller: _repNameCtrl,
                label: 'Representative name',
                isRequired: true,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _repPhoneCtrl,
                label: 'Representative mobile',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _repEmailCtrl,
                label: 'Representative email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
            ],

            const SizedBox(height: 20),

            // ── Consent ─────────────────────────────────────────
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
                      onChanged: (v) =>
                          setState(() => _consentGranted = v ?? false),
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

class _CoverageBadge extends StatelessWidget {
  final bool checking;
  final CoverageCheckResult? result;
  final VoidCallback? onTap;

  const _CoverageBadge({
    required this.checking,
    required this.result,
    this.onTap,
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
            Text(
              'Checking coverage…',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
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
        'Duplicate with ${result!.existingRmName ?? "another RM"}',
      CoverageStatus.requiresReview =>
        '${result!.alternateMatches.length} possible matches',
      CoverageStatus.dnd => 'Do not disturb',
    };

    // Show family match if present
    final familyHint = result!.familyMatch != null
        ? ' · Family: ${result!.familyMatch!.groupName} (${result!.familyMatch!.memberCount} members)'
        : '';

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label$familyHint',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 14, color: color),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: onTap != null
          ? GestureDetector(onTap: onTap, child: body)
          : body,
    );
  }
}
