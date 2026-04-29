import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/consent_type.dart';
import '../../../../core/enums/lead_designation.dart';
import '../../../../core/enums/lead_entity_type.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/consent_record.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/models/key_contact_model.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/reassignment_request.dart';
import '../../../../core/repositories/coverage_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/repositories/reassignment_repository.dart';
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
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../coverage/presentation/widgets/coverage_result_sheet.dart';

/// Create Lead form. Captures the wealth team's prospect intake — entity type
/// is a single 9-value dropdown (Individual + 7 non-individual + Others with a
/// free-text qualifier). Mobile and email are both optional; coverage runs as
/// either becomes long enough to dedupe against. Non-individual leads expose
/// a Key Contact section reusing the IB-side `KeyContactsField` widget.
class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Entity type
  LeadEntityType _entityType = LeadEntityType.individual;
  final _entityTypeOtherCtrl = TextEditingController();

  // Name fields
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _entityNameCtrl = TextEditingController(); // non-individual single field
  final _companyNameCtrl = TextEditingController(); // optional, both types

  // Designation (Individual lead only — for Non-Individual the designation
  // is captured per Key Contact via KeyContactsField's dropdown mode).
  LeadDesignation? _designation;
  final _designationOtherCtrl = TextEditingController();

  // Contact (both optional)
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  // Source
  LeadSource? _source;

  // Key contacts (only emitted when non-individual)
  List<KeyContactModel> _keyContacts = const [];

  // State
  bool _saving = false;
  bool _checkingCoverage = false;
  CoverageCheckResult? _coverage;
  Timer? _coverageDebounce;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onPhoneBlur);
    _emailFocus.addListener(_onEmailBlur);
  }

  @override
  void dispose() {
    _coverageDebounce?.cancel();
    _phoneFocus.removeListener(_onPhoneBlur);
    _emailFocus.removeListener(_onEmailBlur);
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _entityTypeOtherCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _entityNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _designationOtherCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Computed name ──────────────────────────────────────────────────

  String get _computedName {
    if (!_entityType.isIndividual) {
      return _entityNameCtrl.text.trim();
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

  void _onEmailBlur() {
    if (_emailFocus.hasFocus) return;
    if (_emailCtrl.text.trim().contains('@')) _runCoverage();
  }

  void _onTriggerFieldChanged(String _) {
    _coverageDebounce?.cancel();
    _coverageDebounce = Timer(const Duration(milliseconds: 600), () {
      final hasName = _computedName.length >= 3;
      final hasCompany = _companyNameCtrl.text.trim().length >= 3;
      final hasEmail = _emailCtrl.text.trim().contains('@');
      if (hasName || hasCompany || hasEmail) _runCoverage();
    });
  }

  Future<void> _runCoverage() async {
    final name = _computedName;
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final company = _companyNameCtrl.text.trim();
    if (name.isEmpty && phone.isEmpty && email.isEmpty && company.isEmpty) {
      return;
    }

    // Vertical is derived from the logged-in RM's user profile (no form
    // selector). EWG uses Name/Email/Mobile match composition; PWG also
    // includes Company. The mock data restricts matches to Wealth Spectrum
    // (CoverageSource.clientMaster) regardless of vertical.
    final user = context.read<AuthCubit>().state.currentUser;

    setState(() => _checkingCoverage = true);
    final result = await getIt<CoverageRepository>().checkCoverage(
      name: name.isEmpty ? null : name,
      phone: phone.length >= 10 ? phone : null,
      email: email.contains('@') ? email : null,
      company: company.isEmpty ? null : company,
      groupName: company.isEmpty ? null : company,
      vertical: user?.vertical,
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
        // Persist the reassignment request so Admin/MIS can act on it
        // from the Manage Pool → REASSIGNMENT tab. The matched record on
        // the result tells us who currently owns the client.
        if (decision == CoverageDecision.requestReassignment &&
            user != null &&
            result.matchedRecord != null) {
          final matched = result.matchedRecord!;
          await getIt<ReassignmentRepository>().create(
            ReassignmentRequest(
              id: 'RR_${DateTime.now().millisecondsSinceEpoch}',
              matchedClientId: matched.id,
              matchedClientName: matched.clientName,
              sourceRmId: user.id,
              sourceRmName: user.name,
              targetRmId: matched.rmId,
              targetRmName: matched.rmName,
              reason:
                  'Coverage match — ${user.name} requesting reassignment of ${matched.clientName}',
              createdAt: DateTime.now(),
            ),
          );
        }
        if (mounted) {
          showCompassSnack(
            context,
            message: decision == CoverageDecision.requestReassignment
                ? 'Reassignment request submitted to Admin'
                : 'Cancelled',
          );
          context.pop();
        }
      }
    }
  }

  // ── Save ───────────────────────────────────────────────────────────

  /// Hard block: both existingClient AND duplicateLead block submit.
  bool get _isDuplicate =>
      _coverage?.status == CoverageStatus.existingClient ||
      _coverage?.status == CoverageStatus.duplicateLead;

  /// Validation rules:
  ///   - Name (computed for individual / entity name for non-individual) required.
  ///   - When entityType == others, the free-text qualifier is mandatory.
  ///   - Source required.
  ///   - For non-individual: at least one valid Key Contact.
  ///   - Mobile and email are BOTH optional per spec.
  bool get _canSave {
    if (_computedName.isEmpty) return false;
    if (_source == null) return false;
    if (_isDuplicate) return false;
    if (_entityType == LeadEntityType.others &&
        _entityTypeOtherCtrl.text.trim().isEmpty) {
      return false;
    }
    // Designation qualifier required when Individual + designation == Others.
    if (_entityType.isIndividual &&
        _designation == LeadDesignation.others &&
        _designationOtherCtrl.text.trim().isEmpty) {
      return false;
    }
    if (!_entityType.isIndividual) {
      if (_keyContacts.isEmpty) return false;
      if (!_keyContacts.first.isValid) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_canSave) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final leadId = 'LEAD_${now.millisecondsSinceEpoch}';
    // Auto-granted consent record so retention banner / data export keep
    // their existing semantics. The DPDP capture UI was retired from this
    // form per business request.
    final consent = ConsentRecord(
      id: 'CON_${now.millisecondsSinceEpoch}',
      leadId: leadId,
      consentType: DataConsentType.leadCapture,
      grantedAt: now,
      grantedByUserId: user.id,
      grantedByUserName: user.name,
      purposeStatement: DataConsentType.leadCapture.purposeStatement,
    );

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final company = _companyNameCtrl.text.trim();

    final lead = LeadModel(
      id: leadId,
      entityType: _entityType,
      entityTypeOther: _entityType == LeadEntityType.others
          ? _entityTypeOtherCtrl.text.trim()
          : null,
      fullName: _computedName,
      firstName: _entityType.isIndividual
          ? _firstNameCtrl.text.trim()
          : null,
      middleName: _entityType.isIndividual
          ? (_middleNameCtrl.text.trim().isEmpty
              ? null
              : _middleNameCtrl.text.trim())
          : null,
      lastName: _entityType.isIndividual
          ? _lastNameCtrl.text.trim()
          : null,
      // Designation only applies when Individual; Non-Individual leads carry
      // designation per Key Contact (KeyContactsField with dropdown mode).
      designation: _entityType.isIndividual ? _designation : null,
      designationOther: (_entityType.isIndividual &&
              _designation == LeadDesignation.others)
          ? _designationOtherCtrl.text.trim()
          : null,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
      // Company Name maps to both `companyName` (display) and `groupName`
      // (coverage de-dupe key) so existing coverage / family-link logic
      // keeps working unchanged.
      companyName: company.isEmpty ? null : company,
      groupName: company.isEmpty ? null : company,
      keyContacts: _entityType.isIndividual ? const [] : _keyContacts,
      source: _source!,
      stage: LeadStage.lead,
      score: _source!.baseScore,
      assignedRmId: user.id,
      assignedRmName: user.name,
      // Lead inherits the RM's vertical so downstream filters / Get Lead
      // pool segmentation work correctly.
      vertical: user.vertical ?? 'EWG',
      createdAt: now,
      updatedAt: now,
      consentStatus: ConsentStatus.granted,
      consentRecords: [consent],
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
            // ── Lead type (single 9-value dropdown) ──────────────
            const CompassSectionHeader(title: 'Lead type'),
            const SizedBox(height: 10),
            CompassDropdown<LeadEntityType>(
              label: 'Lead type',
              isRequired: true,
              value: _entityType,
              hint: 'Select type',
              items: LeadEntityType.values
                  .map((t) => CompassDropdownItem(value: t, label: t.label))
                  .toList(),
              onChanged: (v) => setState(() {
                _entityType = v ?? LeadEntityType.individual;
                _coverage = null;
                if (_entityType.isIndividual) {
                  _keyContacts = const [];
                }
              }),
            ),
            if (_entityType == LeadEntityType.others) ...[
              const SizedBox(height: 12),
              CompassTextField(
                controller: _entityTypeOtherCtrl,
                label: 'Specify lead type',
                isRequired: true,
                hint: 'e.g. Section 8 Company',
                maxLength: 100,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Required when Others is selected'
                    : null,
              ),
            ],

            const SizedBox(height: 20),

            // ── Name fields ─────────────────────────────────────
            const CompassSectionHeader(title: 'Name'),
            const SizedBox(height: 10),
            if (_entityType.isIndividual) ...[
              CompassTextField(
                controller: _firstNameCtrl,
                label: 'First name',
                isRequired: true,
                onChanged: _onTriggerFieldChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _middleNameCtrl,
                label: 'Middle name',
                onChanged: _onTriggerFieldChanged,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _lastNameCtrl,
                label: 'Last name',
                isRequired: true,
                onChanged: _onTriggerFieldChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              // Designation — Individual leads only. For Non-Individual the
              // designation lives on each Key Contact (see KeyContactsField
              // call site below with useDesignationDropdown: true).
              CompassDropdown<LeadDesignation>(
                label: 'Designation',
                value: _designation,
                hint: 'Select designation',
                items: LeadDesignation.values
                    .map((d) =>
                        CompassDropdownItem(value: d, label: d.label))
                    .toList(),
                onChanged: (v) => setState(() => _designation = v),
              ),
              if (_designation == LeadDesignation.others) ...[
                const SizedBox(height: 12),
                CompassTextField(
                  controller: _designationOtherCtrl,
                  label: 'Specify designation',
                  isRequired: true,
                  hint: 'e.g. Trustee, Authorised Signatory',
                  maxLength: 60,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Required when Others is selected'
                      : null,
                ),
              ],
            ] else ...[
              CompassTextField(
                controller: _entityNameCtrl,
                label: 'Entity name',
                isRequired: true,
                onChanged: _onTriggerFieldChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 12),
            CompassTextField(
              controller: _companyNameCtrl,
              label: 'Company Name',
              hint: 'Optional — used for coverage / family de-dupe',
              prefixIcon: Icons.business_outlined,
              onChanged: _onTriggerFieldChanged,
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

            // ── Contact (both optional) ──────────────────────────
            const CompassSectionHeader(title: 'Contact'),
            const SizedBox(height: 10),
            CompassTextField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              label: 'Mobile number',
              hint: 'Optional',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            CompassTextField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              label: 'Email',
              hint: 'Optional',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),

            // ── Key Contact Person (non-individual only) ────────
            if (!_entityType.isIndividual) ...[
              const SizedBox(height: 20),
              const CompassSectionHeader(title: 'Key contact person'),
              const SizedBox(height: 10),
              KeyContactsField(
                contacts: _keyContacts,
                onChanged: (next) => setState(() => _keyContacts = next),
                // Wealth side gets the Designation dropdown (Promoter /
                // Founder / CEO / Family Office Head / Others). IB capture
                // leaves this default false and keeps free-text designation.
                useDesignationDropdown: true,
              ),
            ],

            const SizedBox(height: 20),

            // ── Source ───────────────────────────────────────────
            const CompassSectionHeader(title: 'Source'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              // Add Lead form shows only RM-pickable sources. The system-
              // assigned tags (hurun / monetizationEvent) are filtered out;
              // they only get attached to pool leads and bulk imports.
              children: LeadSource.addableValues
                  .map((s) => CompassChoiceChip<LeadSource>(
                        value: s,
                        groupValue: _source,
                        label: s.label,
                        onSelected: (v) => setState(() => _source = v),
                      ))
                  .toList(),
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
