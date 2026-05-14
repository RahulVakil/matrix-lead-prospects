import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Country code for the mobile number — defaults to India.
  _CountryCode _countryCode = _kCountryCodes.first;

  // Source
  LeadSource? _source;

  // Key contacts (only emitted when non-individual)
  List<KeyContactModel> _keyContacts = const [];

  // State
  bool _saving = false;

  @override
  void dispose() {
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
  // Coverage runs ONLY when the RM taps Save Lead. No inline checks
  // while typing — RMs found the early badges confusing. On Save, we
  // either save (clear) or block + show the de-dupe sheet with two
  // options: Request reassignment, or Cancel.

  /// Whether the digits in `_phoneCtrl` form a complete number for the
  /// currently-selected country code (length within range + leading digit
  /// regex, if any). Used to gate the coverage payload and validator.
  bool _isPhoneComplete() {
    final digits = _phoneCtrl.text.trim();
    if (digits.length < _countryCode.minDigits ||
        digits.length > _countryCode.maxDigits) {
      return false;
    }
    final lead = _countryCode.leadingDigits;
    if (lead != null && !lead.hasMatch(digits)) return false;
    return true;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').trim();
    if (digits.isEmpty) return null; // mobile is optional
    if (digits.length < _countryCode.minDigits) {
      return _countryCode.minDigits == _countryCode.maxDigits
          ? 'Enter ${_countryCode.minDigits} digits'
          : 'Enter ${_countryCode.minDigits}-${_countryCode.maxDigits} digits';
    }
    if (digits.length > _countryCode.maxDigits) {
      return _countryCode.minDigits == _countryCode.maxDigits
          ? 'Enter ${_countryCode.minDigits} digits'
          : 'Enter ${_countryCode.minDigits}-${_countryCode.maxDigits} digits';
    }
    final lead = _countryCode.leadingDigits;
    if (lead != null && !lead.hasMatch(digits)) {
      return _countryCode.leadingHint ?? 'Invalid mobile number';
    }
    return null;
  }

  /// Runs coverage as a single check at Save time. Returns:
  ///   - the result if it's clear (caller proceeds with save), OR
  ///   - null if the RM hit a de-dupe and chose Request reassignment /
  ///     Cancel from the result sheet (caller stops the save).
  ///
  /// On request-reassignment, the request is created here and the screen
  /// is popped. On cancel, the screen is popped. So a non-null return
  /// always means "caller should proceed with the save".
  Future<CoverageCheckResult?> _runCoverageOnSave() async {
    final name = _computedName;
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final company = _companyNameCtrl.text.trim();
    final user = context.read<AuthCubit>().state.currentUser;

    final result = await getIt<CoverageRepository>().checkCoverage(
      name: name.isEmpty ? null : name,
      phone: _isPhoneComplete() ? phone : null,
      email: email.contains('@') ? email : null,
      company: company.isEmpty ? null : company,
      groupName: company.isEmpty ? null : company,
      vertical: user?.vertical,
    );

    if (result.canProceed) return result;

    if (!mounted) return null;
    final decision = await showCoverageResultSheet(context, result);
    if (!mounted) return null;

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
      if (mounted) {
        showCompassSnack(context,
            message: 'Reassignment request submitted to Admin',
            type: CompassSnackType.success);
        context.pop();
      }
    } else if (decision == CoverageDecision.cancel || decision == null) {
      // Stay on the form so the RM can edit the entry; no toast spam.
    }
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────

  /// Validation rules:
  ///   - Name (computed for individual / entity name for non-individual) required.
  ///   - When entityType == others, the free-text qualifier is mandatory.
  ///   - Source required.
  ///   - For non-individual: at least one valid Key Contact.
  ///   - Mobile and email are BOTH optional per spec.
  bool get _canSave {
    if (_computedName.isEmpty) return false;
    if (_source == null) return false;
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

    // Single coverage check at Save time. Clear → proceed. Hit → the
    // helper shows the de-dupe sheet and either creates a reassignment
    // request (and pops the screen) or returns null so we abort the save
    // and let the RM edit.
    final coverageResult = await _runCoverageOnSave();
    if (!mounted) return;
    if (coverageResult == null) {
      setState(() => _saving = false);
      return;
    }

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

    final phoneDigits = _phoneCtrl.text.trim();
    final phone = phoneDigits.isEmpty
        ? ''
        : '${_countryCode.dialCode} $phoneDigits';
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _middleNameCtrl,
                label: 'Middle name',
              ),
              const SizedBox(height: 12),
              CompassTextField(
                controller: _lastNameCtrl,
                label: 'Last name',
                isRequired: true,
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
            ),

            const SizedBox(height: 20),

            // ── Contact (both optional) ──────────────────────────
            const CompassSectionHeader(title: 'Contact'),
            const SizedBox(height: 10),
            // Mobile number = country-code dropdown (default India / +91)
            // + digits-only TextField. Validation length & leading digit are
            // driven by the selected country code's rules.
            _MobileWithCountryCode(
              countryCode: _countryCode,
              countries: _kCountryCodes,
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              validator: _validatePhone,
              onCountryChanged: (c) {
                setState(() {
                  _countryCode = c;
                  // Trim digits down to the new country's max length so the
                  // visible value never violates the new constraint.
                  if (_phoneCtrl.text.length > c.maxDigits) {
                    _phoneCtrl.text = _phoneCtrl.text.substring(0, c.maxDigits);
                  }
                });
              },
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
// Country code data + mobile-number-with-country-code field.
// India is intentionally first so it can be the default selection.

class _CountryCode {
  final String iso; // ISO-2 e.g. 'IN'
  final String dialCode; // e.g. '+91'
  final String name; // e.g. 'India'
  final String flag; // emoji
  final int minDigits;
  final int maxDigits;
  final RegExp? leadingDigits; // optional first-digit constraint
  final String? leadingHint; // shown when leadingDigits fails

  const _CountryCode({
    required this.iso,
    required this.dialCode,
    required this.name,
    required this.flag,
    required this.minDigits,
    required this.maxDigits,
    this.leadingDigits,
    this.leadingHint,
  });
}

// Common country codes for Indian wealth / NRI clients. India first so it
// is the default. Mobile-number length & leading-digit rules per TRAI /
// national numbering plans.
final List<_CountryCode> _kCountryCodes = [
  _CountryCode(
    iso: 'IN',
    dialCode: '+91',
    name: 'India',
    flag: '🇮🇳',
    minDigits: 10,
    maxDigits: 10,
    leadingDigits: RegExp(r'^[6-9]'),
    leadingHint: 'Indian mobile must start with 6, 7, 8 or 9',
  ),
  _CountryCode(
    iso: 'AE',
    dialCode: '+971',
    name: 'United Arab Emirates',
    flag: '🇦🇪',
    minDigits: 9,
    maxDigits: 9,
    leadingDigits: RegExp(r'^5'),
    leadingHint: 'UAE mobile must start with 5',
  ),
  _CountryCode(
    iso: 'SG',
    dialCode: '+65',
    name: 'Singapore',
    flag: '🇸🇬',
    minDigits: 8,
    maxDigits: 8,
    leadingDigits: RegExp(r'^[89]'),
    leadingHint: 'Singapore mobile must start with 8 or 9',
  ),
  _CountryCode(
    iso: 'GB',
    dialCode: '+44',
    name: 'United Kingdom',
    flag: '🇬🇧',
    minDigits: 10,
    maxDigits: 10,
    leadingDigits: RegExp(r'^7'),
    leadingHint: 'UK mobile must start with 7',
  ),
  _CountryCode(
    iso: 'US',
    dialCode: '+1',
    name: 'United States',
    flag: '🇺🇸',
    minDigits: 10,
    maxDigits: 10,
  ),
  _CountryCode(
    iso: 'CA',
    dialCode: '+1',
    name: 'Canada',
    flag: '🇨🇦',
    minDigits: 10,
    maxDigits: 10,
  ),
  _CountryCode(
    iso: 'AU',
    dialCode: '+61',
    name: 'Australia',
    flag: '🇦🇺',
    minDigits: 9,
    maxDigits: 9,
    leadingDigits: RegExp(r'^4'),
    leadingHint: 'Australian mobile must start with 4',
  ),
  _CountryCode(
    iso: 'SA',
    dialCode: '+966',
    name: 'Saudi Arabia',
    flag: '🇸🇦',
    minDigits: 9,
    maxDigits: 9,
    leadingDigits: RegExp(r'^5'),
    leadingHint: 'Saudi mobile must start with 5',
  ),
  _CountryCode(
    iso: 'HK',
    dialCode: '+852',
    name: 'Hong Kong',
    flag: '🇭🇰',
    minDigits: 8,
    maxDigits: 8,
    leadingDigits: RegExp(r'^[569]'),
    leadingHint: 'Hong Kong mobile must start with 5, 6 or 9',
  ),
  _CountryCode(
    iso: 'CH',
    dialCode: '+41',
    name: 'Switzerland',
    flag: '🇨🇭',
    minDigits: 9,
    maxDigits: 9,
    leadingDigits: RegExp(r'^7'),
    leadingHint: 'Swiss mobile must start with 7',
  ),
];

class _MobileWithCountryCode extends StatelessWidget {
  final _CountryCode countryCode;
  final List<_CountryCode> countries;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final ValueChanged<_CountryCode> onCountryChanged;

  const _MobileWithCountryCode({
    required this.countryCode,
    required this.countries,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: 'Mobile number',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code dropdown — fixed-width so the phone field gets
            // the rest of the row. Selected state shows just flag + dial
            // code; the menu shows full country name for disambiguation.
            SizedBox(
              width: 118,
              child: DropdownButtonFormField<_CountryCode>(
                initialValue: countryCode,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.navyPrimary, width: 1.5),
                  ),
                ),
                style: AppTextStyles.bodyLarge,
                selectedItemBuilder: (ctx) => countries
                    .map((c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${c.flag}  ${c.dialCode}',
                            style: AppTextStyles.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                items: countries
                    .map(
                      (c) => DropdownMenuItem<_CountryCode>(
                        value: c,
                        child: Row(
                          children: [
                            Text(c.flag,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                style: AppTextStyles.bodyLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(c.dialCode,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (c) {
                  if (c != null) onCountryChanged(c);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(countryCode.maxDigits),
                  ],
                  validator: validator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: countryCode.minDigits == countryCode.maxDigits
                        ? '${countryCode.minDigits}-digit mobile (optional)'
                        : '${countryCode.minDigits}-${countryCode.maxDigits} digits (optional)',
                    counterText: '',
                    prefixIcon: const Icon(Icons.phone_outlined,
                        size: 20, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.navyPrimary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.errorRedAlt),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.errorRedAlt, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
