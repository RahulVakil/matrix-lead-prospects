import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_text_field.dart';

Future<String?> showSendBackSheet(
  BuildContext context,
  String leadCompany, {
  String title = 'Send back to RM',
  String hintText = 'What does the RM need to fix or add?',
}) {
  return showCompassSheet<String>(
    context,
    title: title,
    child: _SendBackBody(leadCompany: leadCompany, hintText: hintText),
  );
}

class _SendBackBody extends StatefulWidget {
  final String leadCompany;
  final String hintText;
  const _SendBackBody({required this.leadCompany, required this.hintText});

  @override
  State<_SendBackBody> createState() => _SendBackBodyState();
}

class _SendBackBodyState extends State<_SendBackBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadCompany, style: AppTextStyles.bodySmall),
        const SizedBox(height: 14),
        CompassTextField(
          controller: _ctrl,
          label: 'Remarks',
          hint: widget.hintText,
          isRequired: true,
          maxLines: 4,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        CompassButton.danger(
          label: 'Send back',
          onPressed: () {
            final remarks = _ctrl.text.trim();
            if (remarks.isEmpty) return;
            Navigator.of(context).pop(remarks);
          },
        ),
      ],
    );
  }
}
