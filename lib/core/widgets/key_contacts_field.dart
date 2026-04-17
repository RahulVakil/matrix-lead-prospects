import 'package:flutter/material.dart';
import '../models/key_contact_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'compass_text_field.dart';

/// RM-4: Key Contacts editor for IB Lead Capture.
/// Contact 1 is mandatory (Name, Designation, Mobile, Email).
/// Contact 2 is optional — shown via "+ Add Another Key Contact" button.
/// Max 2 contacts.
class KeyContactsField extends StatelessWidget {
  final List<KeyContactModel> contacts;
  final ValueChanged<List<KeyContactModel>> onChanged;
  final String? label;

  const KeyContactsField({
    super.key,
    required this.contacts,
    required this.onChanged,
    this.label,
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
