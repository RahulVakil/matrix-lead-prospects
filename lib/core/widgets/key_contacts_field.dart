import 'package:flutter/material.dart';
import '../models/key_contact_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'compass_text_field.dart';

/// Multi-row name+designation editor used for IB Lead Capture's
/// "Key Contacts" section.
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
    onChanged([...contacts, const KeyContactModel(name: '', designation: '')]);
  }

  void _remove(int index) {
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: CompassTextField(
                    initialValue: c.name,
                    hint: 'Name',
                    onChanged: (v) => _update(i, KeyContactModel(name: v, designation: c.designation)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: CompassTextField(
                    initialValue: c.designation,
                    hint: 'Designation',
                    onChanged: (v) => _update(i, KeyContactModel(name: c.name, designation: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                  onPressed: () => _remove(i),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add contact'),
          ),
        ),
      ],
    );
  }
}
