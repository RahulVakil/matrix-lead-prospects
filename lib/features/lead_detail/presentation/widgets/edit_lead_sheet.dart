import 'package:flutter/material.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Bottom sheet to edit a lead's basic details post-creation.
Future<LeadModel?> showEditLeadSheet(BuildContext context, LeadModel lead) {
  return showCompassSheet<LeadModel>(
    context,
    title: 'Edit details',
    child: _EditLeadBody(lead: lead),
  );
}

class _EditLeadBody extends StatefulWidget {
  final LeadModel lead;
  const _EditLeadBody({required this.lead});

  @override
  State<_EditLeadBody> createState() => _EditLeadBodyState();
}

class _EditLeadBodyState extends State<_EditLeadBody> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _company;
  late final TextEditingController _city;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.lead.fullName);
    _phone = TextEditingController(text: widget.lead.phone ?? '');
    _email = TextEditingController(text: widget.lead.email ?? '');
    _company = TextEditingController(text: widget.lead.companyName ?? '');
    _city = TextEditingController(text: widget.lead.city ?? '');
    _notes = TextEditingController(text: widget.lead.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompassTextField(
          controller: _name,
          label: 'Full name',
          isRequired: true,
        ),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _phone,
          label: 'Phone',
          isRequired: true,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _company,
          label: 'Company / Group',
          prefixIcon: Icons.apartment_outlined,
        ),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _city,
          label: 'City',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _notes,
          label: 'Notes',
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 20),
        CompassButton(
          label: 'Save changes',
          onPressed: () {
            final updated = widget.lead.copyWith(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
              city: _city.text.trim().isEmpty ? null : _city.text.trim(),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              groupName: _company.text.trim().isEmpty ? null : _company.text.trim(),
              updatedAt: DateTime.now(),
            );
            Navigator.of(context).pop(updated);
          },
        ),
        const SizedBox(height: 10),
        CompassButton.tertiary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
