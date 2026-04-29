import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_snackbar.dart';

/// DPDP data portability — exports all data held for a lead as
/// a structured text summary that the RM can copy to clipboard.
Future<void> showDataExportSheet(BuildContext context, LeadModel lead) {
  return showCompassSheet(
    context,
    title: 'Data export',
    child: _DataExportBody(lead: lead),
  );
}

class _DataExportBody extends StatelessWidget {
  final LeadModel lead;
  const _DataExportBody({required this.lead});

  String get _export {
    final buf = StringBuffer();
    buf.writeln('=== LEAD DATA EXPORT ===');
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('Lead ID: ${lead.id}');
    buf.writeln();
    buf.writeln('-- Identity --');
    buf.writeln('Name: ${lead.fullName}');
    if ((lead.phone ?? '').isNotEmpty) buf.writeln('Phone: ${lead.phone}');
    if (lead.email != null) buf.writeln('Email: ${lead.email}');
    if (lead.companyName != null) buf.writeln('Company: ${lead.companyName}');
    if (lead.city != null) buf.writeln('City: ${lead.city}');
    if (lead.groupName != null) buf.writeln('Group: ${lead.groupName}');
    buf.writeln('Vertical: ${lead.vertical}');
    buf.writeln();
    buf.writeln('-- Pipeline --');
    buf.writeln('Stage: ${lead.stage.label}');
    buf.writeln('Source: ${lead.source.label}');
    buf.writeln('Owner: ${lead.assignedRmName}');
    buf.writeln('Created: ${lead.createdAt.toIso8601String()}');
    buf.writeln('Last contact: ${lead.lastContactedAt?.toIso8601String() ?? 'Never'}');
    if (lead.estimatedAum != null) buf.writeln('Est. AUM: ${lead.aumDisplay}');
    buf.writeln('Products: ${lead.productInterest.join(', ')}');
    buf.writeln();
    buf.writeln('-- Consent --');
    buf.writeln('Status: ${lead.consentStatus.label}');
    for (final c in lead.consentRecords) {
      buf.writeln('  ${c.consentType.label}: ${c.statusDisplay} (${c.grantedAt.toIso8601String()})');
    }
    buf.writeln();
    buf.writeln('-- Activities (${lead.recentActivities.length}) --');
    for (final a in lead.recentActivities.take(20)) {
      buf.writeln('  ${a.dateTime.toIso8601String()} ${a.type.label} ${a.notes ?? ''}');
    }
    buf.writeln();
    buf.writeln('-- Retention --');
    buf.writeln('Status: ${lead.retentionStatus.label}');
    buf.writeln();
    buf.writeln('=== END OF EXPORT ===');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final text = _export;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'DPDP Act 2023 — Right to Data Portability',
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        CompassButton(
          label: 'Copy to clipboard',
          icon: Icons.copy,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            Navigator.pop(context);
            showCompassSnack(
              context,
              message: 'Data copied to clipboard',
              type: CompassSnackType.success,
            );
          },
        ),
      ],
    );
  }
}
