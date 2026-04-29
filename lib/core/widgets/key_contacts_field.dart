import 'package:flutter/material.dart';
import '../enums/lead_designation.dart';
import '../models/key_contact_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'compass_dropdown.dart';
import 'compass_text_field.dart';

/// Key Contacts editor.
/// Contact 1 is mandatory (Name, Designation, Mobile, Email).
/// Contact 2 is optional — shown via "+ Add Another Key Contact" button.
/// Max 2 contacts.
///
/// IB callers leave [useDesignationDropdown] at the default `false` — the
/// designation field renders as a free-text input (legacy IB behavior).
/// The wealth Non-Individual capture flow passes `true` so designation is a
/// dropdown of LeadDesignation values; picking "Others" reveals a free-text
/// qualifier and the composed string ("Others: <qualifier>") is stored back
/// into the existing [KeyContactModel.designation] String. No model change.
class KeyContactsField extends StatelessWidget {
  final List<KeyContactModel> contacts;
  final ValueChanged<List<KeyContactModel>> onChanged;
  final String? label;
  final bool useDesignationDropdown;

  const KeyContactsField({
    super.key,
    required this.contacts,
    required this.onChanged,
    this.label,
    this.useDesignationDropdown = false,
  });

  void _add() {
    if (contacts.length >= 2) return;
    onChanged([
      ...contacts,
      const KeyContactModel(name: '', designation: ''),
    ]);
  }

  void _remove(int index) {
    if (index == 0 && contacts.length == 1) return; // Contact 1 is mandatory
    final next = [...contacts]..removeAt(index);
    onChanged(next);
  }

  void _update(int index, KeyContactModel updated) {
    final next = [...contacts];
    next[index] = updated;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure at least 1 contact exists (Contact 1 mandatory)
    if (contacts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged([const KeyContactModel(name: '', designation: '')]);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...List.generate(contacts.length, (i) {
          final c = contacts[i];
          final isMandatory = i == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMandatory
                          ? 'Contact 1 (mandatory)'
                          : 'Contact 2 (optional)',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (!isMandatory)
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.errorRed),
                        tooltip: 'Remove',
                        onPressed: () => _remove(i),
                        splashRadius: 16,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                CompassTextField(
                  initialValue: c.name,
                  label: 'Name',
                  isRequired: isMandatory,
                  onChanged: (v) => _update(i, c.copyWith(name: v)),
                ),
                const SizedBox(height: 8),
                if (useDesignationDropdown)
                  _DesignationDropdownField(
                    initialDesignation: c.designation,
                    isRequired: isMandatory,
                    onChanged: (composed) =>
                        _update(i, c.copyWith(designation: composed)),
                  )
                else
                  CompassTextField(
                    initialValue: c.designation,
                    label: 'Designation',
                    isRequired: isMandatory,
                    onChanged: (v) => _update(i, c.copyWith(designation: v)),
                  ),
                const SizedBox(height: 8),
                CompassTextField(
                  initialValue: c.mobile,
                  label: 'Mobile No.',
                  isRequired: isMandatory,
                  hint: '+91 XXXXX XXXXX',
                  prefixIcon: Icons.phone_outlined,
                  onChanged: (v) => _update(i, c.copyWith(mobile: v)),
                ),
                const SizedBox(height: 8),
                CompassTextField(
                  initialValue: c.email,
                  label: 'Email ID',
                  isRequired: isMandatory,
                  hint: 'name@company.com',
                  prefixIcon: Icons.email_outlined,
                  onChanged: (v) => _update(i, c.copyWith(email: v)),
                ),
              ],
            ),
          );
        }),
        if (contacts.length < 2)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Add Another Key Contact'),
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
    );
  }
}

/// Composed dropdown + free-text qualifier for the wealth-side Key Contact
/// designation. The composed value (e.g. "CEO" or "Others: Section 8 head")
/// is written into the existing String field via [onChanged] — no model
/// change to KeyContactModel is needed.
class _DesignationDropdownField extends StatefulWidget {
  final String initialDesignation;
  final bool isRequired;
  final ValueChanged<String> onChanged;

  const _DesignationDropdownField({
    required this.initialDesignation,
    required this.isRequired,
    required this.onChanged,
  });

  @override
  State<_DesignationDropdownField> createState() =>
      _DesignationDropdownFieldState();
}

class _DesignationDropdownFieldState extends State<_DesignationDropdownField> {
  LeadDesignation? _selected;
  final _qualifierCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.initialDesignation;
    if (s.startsWith('Others:')) {
      _selected = LeadDesignation.others;
      _qualifierCtrl.text = s.substring('Others:'.length).trim();
    } else if (s == LeadDesignation.others.label) {
      _selected = LeadDesignation.others;
    } else {
      for (final d in LeadDesignation.values) {
        if (d != LeadDesignation.others && d.label == s) {
          _selected = d;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _qualifierCtrl.dispose();
    super.dispose();
  }

  String _compose() {
    if (_selected == null) return '';
    if (_selected == LeadDesignation.others) {
      final q = _qualifierCtrl.text.trim();
      return q.isEmpty ? 'Others' : 'Others: $q';
    }
    return _selected!.label;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompassDropdown<LeadDesignation>(
          label: 'Designation',
          isRequired: widget.isRequired,
          value: _selected,
          hint: 'Select designation',
          items: LeadDesignation.values
              .map((d) => CompassDropdownItem(value: d, label: d.label))
              .toList(),
          onChanged: (v) {
            setState(() => _selected = v);
            widget.onChanged(_compose());
          },
        ),
        if (_selected == LeadDesignation.others) ...[
          const SizedBox(height: 8),
          CompassTextField(
            controller: _qualifierCtrl,
            label: 'Specify designation',
            isRequired: widget.isRequired,
            maxLength: 60,
            onChanged: (_) => widget.onChanged(_compose()),
          ),
        ],
      ],
    );
  }
}
