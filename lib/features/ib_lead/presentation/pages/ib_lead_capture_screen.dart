import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_dropdown.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/compass_text_field.dart';
import '../../../../core/widgets/inr_currency_field.dart';
import '../../../../core/widgets/key_contacts_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../notifier/providers.dart';

/// IB Lead Capture form. Single scrollable screen, Riverpod-driven.
class IbLeadCaptureScreen extends StatelessWidget {
  final String? clientName;
  final String? clientCode;
  final String? companyName;

  const IbLeadCaptureScreen({
    super.key,
    this.clientName,
    this.clientCode,
    this.companyName,
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
    );

    return _CaptureBody(seed: seed);
  }
}

class _CaptureBody extends ConsumerWidget {
  final IbLeadFormSeed seed;
  const _CaptureBody({required this.seed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ibLeadFormProvider(seed));
    final notifier = ref.read(ibLeadFormProvider(seed).notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: const CompassAppBar(
        title: 'Capture IB Lead',
        subtitle: 'Goes to Branch Head for review',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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
          const SizedBox(height: 16),
          KeyContactsField(
            label: 'Key contacts',
            contacts: state.contacts,
            onChanged: notifier.setContacts,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Deal Details'),
          const SizedBox(height: 12),
          CompassDropdown<IbDealType>(
            label: 'Type of deal',
            isRequired: true,
            value: state.dealType,
            hint: 'Choose deal type',
            items: IbDealType.values
                .map((d) => CompassDropdownItem(value: d, label: d.label))
                .toList(),
            onChanged: notifier.setDealType,
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
          INRCurrencyField(
            label: 'Potential deal value',
            value: state.dealValue,
            onChanged: notifier.setDealValue,
          ),
          const SizedBox(height: 8),
          Text('Or pick a range', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IbDealValueRange.values
                .map(
                  (r) => CompassChoiceChip<IbDealValueRange>(
                    value: r,
                    groupValue: state.dealValueRange,
                    label: r.label,
                    onSelected: notifier.setDealValueRange,
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
          Text('Deal stage *', style: AppTextStyles.labelSmall),
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
          _TimelinePicker(
            month: state.timelineMonth,
            year: state.timelineYear,
            onChanged: notifier.setTimeline,
          ),

          const SizedBox(height: 24),
          const CompassSectionHeader(title: 'Context'),
          const SizedBox(height: 8),
          Text('How was this identified? *', style: AppTextStyles.labelSmall),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: state.isConfidential,
                activeThumbColor: AppColors.errorRedAlt,
                onChanged: notifier.setConfidential,
              ),
              const SizedBox(width: 8),
              Text('Mark as Confidential', style: AppTextStyles.bodyMedium),
            ],
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: CompassButton.secondary(
                  label: 'Save Draft',
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final saved = await notifier.saveDraft();
                          if (saved != null && context.mounted) {
                            showCompassSnack(
                              context,
                              message: 'Draft saved',
                              type: CompassSnackType.success,
                            );
                            context.pop();
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CompassButton(
                  label: 'Submit',
                  isLoading: state.isSubmitting,
                  onPressed: state.isReadyToSubmit
                      ? () async {
                          final saved = await notifier.submit();
                          if (saved != null && context.mounted) {
                            showCompassSnack(
                              context,
                              message: 'Sent to Branch Head for review',
                              type: CompassSnackType.success,
                            );
                            context.pop();
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelinePicker extends StatelessWidget {
  final int? month;
  final int? year;
  final void Function(int month, int year) onChanged;

  const _TimelinePicker({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(4, (i) => now.year + i);
    return Row(
      children: [
        Expanded(
          child: CompassDropdown<int>(
            label: 'Timeline month',
            value: month,
            isRequired: true,
            items: List.generate(
              12,
              (i) => CompassDropdownItem(
                value: i + 1,
                label: const [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ][i],
              ),
            ),
            onChanged: (m) {
              if (m != null) onChanged(m, year ?? now.year);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CompassDropdown<int>(
            label: 'Year',
            value: year,
            isRequired: true,
            items: years
                .map((y) => CompassDropdownItem(value: y, label: '$y'))
                .toList(),
            onChanged: (y) {
              if (y != null) onChanged(month ?? now.month, y);
            },
          ),
        ),
      ],
    );
  }
}
