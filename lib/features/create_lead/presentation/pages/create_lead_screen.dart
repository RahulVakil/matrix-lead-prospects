import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_source.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/coverage_check_result.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/coverage_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../coverage/presentation/widgets/coverage_result_sheet.dart';

/// Four-field lead capture: name, mobile, source, products. Coverage Check
/// runs on phone blur. Everything else lives on Lead Detail post-first-contact.
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
  final _phoneFocus = FocusNode();

  LeadSource? _source;
  final Set<String> _productSet = {};
  bool _saving = false;
  CoverageCheckResult? _coverageResult;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onPhoneFocusChange);
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onPhoneFocusChange);
    _phoneFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onPhoneFocusChange() async {
    if (_phoneFocus.hasFocus) return;
    final p = _phoneController.text.trim();
    if (p.length < 10) return;
    final result = await getIt<CoverageRepository>().checkCoverage(
      phone: p,
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _coverageResult = result);
    if (!result.canProceed) {
      final decision = await showCoverageResultSheet(context, result);
      if (decision == CoverageDecision.cancel || decision == CoverageDecision.requestReassignment) {
        if (mounted) {
          showCompassSnack(
            context,
            message: decision == CoverageDecision.requestReassignment
                ? 'Reassignment requested'
                : 'Capture cancelled',
            type: CompassSnackType.info,
          );
          context.pop();
        }
      }
    }
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10 &&
      _source != null &&
      _productSet.isNotEmpty &&
      (_coverageResult?.status != CoverageStatus.existingClient);

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_source == null || _productSet.isEmpty) return;

    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final lead = LeadModel(
      id: 'LEAD_${now.millisecondsSinceEpoch}',
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      source: _source!,
      stage: LeadStage.lead,
      score: _source!.baseScore,
      productInterest: _productSet.toList(),
      assignedRmId: user.id,
      assignedRmName: user.name,
      createdAt: now,
      updatedAt: now,
    );

    await getIt<LeadRepository>().createLead(lead);

    if (!mounted) return;
    setState(() => _saving = false);
    showCompassSnack(context, message: 'Lead added', type: CompassSnackType.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CompassAppBar(title: 'New Lead'),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            CompassTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'e.g. Rajesh Mehta',
              isRequired: true,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            CompassTextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              label: 'Mobile',
              hint: '10-digit number',
              isRequired: true,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
              validator: (v) => v == null || v.trim().length < 10 ? 'Enter 10 digits' : null,
            ),
            if (_coverageResult != null && _coverageResult!.canProceed)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  '✓ Coverage clear',
                  style: AppTextStyles.caption.copyWith(color: Colors.green),
                ),
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: CompassButton(
            label: 'Save Lead',
            isLoading: _saving,
            onPressed: _canSave ? _save : null,
          ),
        ),
      ),
    );
  }
}
