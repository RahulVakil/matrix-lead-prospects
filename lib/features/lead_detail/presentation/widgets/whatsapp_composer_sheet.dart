import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/compass_bottom_sheet.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_chip.dart';
import '../../../../core/widgets/compass_date_field.dart';
import '../../../../core/widgets/compass_text_field.dart';

/// Predefined message templates. Variables: {firstName}, {rmName}, {firmName}.
class _WaTemplate {
  final String key;
  final String label;
  final String body;
  const _WaTemplate({required this.key, required this.label, required this.body});
}

const _kTemplates = <_WaTemplate>[
  _WaTemplate(
    key: 'intro',
    label: 'Intro',
    body:
        'Hi {firstName}, this is {rmName} from {firmName}. Thank you for the introduction — would love to set up a quick call to understand your wealth goals. When works for you?',
  ),
  _WaTemplate(
    key: 'followup_call',
    label: 'Follow-up after call',
    body:
        'Hi {firstName}, thank you for your time on the call. As discussed, sharing a quick summary and the next steps. Let me know if anything needs clarification.',
  ),
  _WaTemplate(
    key: 'proposal',
    label: 'Share proposal',
    body:
        'Hi {firstName}, sharing the proposal as discussed. Happy to walk you through any section in detail — call me whenever convenient.',
  ),
  _WaTemplate(
    key: 'custom',
    label: 'Custom',
    body: '',
  ),
];

/// Mock library of attachable assets shown to the RM when picking files
/// for the Share-proposal flow. Production would pull from a real
/// document library / DAM.
const _kProposalLibrary = <_AttachOption>[
  _AttachOption('JM Wealth Brochure 2026.pdf', '2.3 MB'),
  _AttachOption('PMS Strategy Note.pdf', '1.1 MB'),
  _AttachOption('AIF Cat-3 Overview.pdf', '0.9 MB'),
  _AttachOption('Family Office Services.pdf', '1.4 MB'),
  _AttachOption('Discretionary PMS Factsheet.pdf', '0.7 MB'),
  _AttachOption('Estate Planning Brief.pdf', '0.6 MB'),
];

class _AttachOption {
  final String name;
  final String size;
  const _AttachOption(this.name, this.size);
}

class WhatsappComposerResult {
  /// The full rendered message body that was sent.
  final String message;

  /// Template key used (e.g. 'intro' / 'custom').
  final String templateKey;

  /// Names of files the RM picked to share.
  final List<String> attachmentNames;

  /// Next action selected by the RM (or null if `none`).
  final NextActionType? nextActionType;
  final DateTime? nextActionDate;

  const WhatsappComposerResult({
    required this.message,
    required this.templateKey,
    required this.attachmentNames,
    required this.nextActionType,
    required this.nextActionDate,
  });
}

/// Bottom sheet for composing a WhatsApp message to a lead.
///
/// Lifecycle:
/// 1. RM picks a template (or Custom) and edits the message.
/// 2. RM optionally picks a Next action.
/// 3. On Send, opens `wa.me/<digits>?text=<encoded>` in WhatsApp. Returns
///    the [WhatsappComposerResult] for the caller to log + setNextAction.
class WhatsappComposerSheet {
  static Future<WhatsappComposerResult?> show(
    BuildContext context, {
    required String leadName,
    required String leadFirstName,
    required String rmName,
    required String phone,
  }) {
    return showCompassSheet<WhatsappComposerResult>(
      context,
      title: 'Message $leadName',
      child: _Body(
        leadName: leadName,
        leadFirstName: leadFirstName,
        rmName: rmName,
        phone: phone,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final String leadName;
  final String leadFirstName;
  final String rmName;
  final String phone;
  const _Body({
    required this.leadName,
    required this.leadFirstName,
    required this.rmName,
    required this.phone,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  _WaTemplate _template = _kTemplates.first;
  final _messageCtrl = TextEditingController();
  final _attachments = <String>[];
  NextActionType? _nextActionType;
  DateTime? _nextActionDate;
  bool _sending = false;

  bool get _supportsAttachments =>
      _template.key == 'proposal' || _template.key == 'custom';

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(() => setState(() {}));
    _applyTemplate(_template);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String _render(String body) {
    return body
        .replaceAll('{firstName}', widget.leadFirstName)
        .replaceAll('{rmName}', widget.rmName)
        .replaceAll('{firmName}', 'JM Financial');
  }

  void _applyTemplate(_WaTemplate t) {
    _template = t;
    _messageCtrl.text = _render(t.body);
    // Attachments only make sense for proposal / custom; clear when
    // switching to a template that doesn't support them.
    if (!(t.key == 'proposal' || t.key == 'custom')) {
      _attachments.clear();
    }
    setState(() {});
  }

  Future<void> _pickAttachment() async {
    final available =
        _kProposalLibrary.where((a) => !_attachments.contains(a.name)).toList();
    if (available.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Attach a file',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600),
              ),
            ),
            ...available.map(
              (a) => ListTile(
                leading: const Icon(Icons.picture_as_pdf,
                    color: Color(0xFFE53935)),
                title: Text(a.name, style: AppTextStyles.bodyMedium),
                subtitle: Text(a.size,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                onTap: () => Navigator.of(ctx).pop(a.name),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _attachments.add(picked));
  }

  Future<void> _send() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);

    final digits = widget.phone.replaceAll(RegExp(r'[^\d]'), '');
    final waNum = digits.startsWith('91') ? digits : '91$digits';
    final uri = Uri.parse('https://wa.me/$waNum?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      WhatsappComposerResult(
        message: msg,
        templateKey: _template.key,
        attachmentNames: List.unmodifiable(_attachments),
        nextActionType: _nextActionType,
        nextActionDate: _nextActionDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _messageCtrl.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.leadName, style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),

        Text('Template', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kTemplates
              .map(
                (t) => CompassChoiceChip<String>(
                  value: t.key,
                  groupValue: _template.key,
                  label: t.label,
                  onSelected: (_) => _applyTemplate(t),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),

        CompassTextField(
          controller: _messageCtrl,
          label: 'Message',
          hint: 'Type your message…',
          maxLines: 6,
          maxLength: 1024,
        ),

        // ── Attachments (only for proposal / custom templates) ──
        if (_supportsAttachments) ...[
          const SizedBox(height: 12),
          Text('Attachments', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in _attachments)
                _AttachmentChip(
                  name: name,
                  onRemove: () => setState(() => _attachments.remove(name)),
                ),
              ActionChip(
                avatar: const Icon(Icons.attach_file,
                    size: 16, color: AppColors.navyPrimary),
                label: Text(
                  _attachments.isEmpty ? 'Attach file' : 'Add another',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.navyPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor:
                    AppColors.navyPrimary.withValues(alpha: 0.08),
                side: BorderSide(
                    color: AppColors.navyPrimary.withValues(alpha: 0.4)),
                onPressed: _pickAttachment,
              ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tip: After WhatsApp opens, tap the 📎 icon there to add these files.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],

        const SizedBox(height: 16),

        // ── Set a follow-up (optional) — same wording as other sheets ──
        Text('Set a follow-up (optional)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NextActionType.values
              .map(
                (n) => CompassChoiceChip<NextActionType>(
                  value: n,
                  groupValue: _nextActionType,
                  label: n.label,
                  icon: n.icon,
                  onSelected: (v) => setState(() => _nextActionType = v),
                ),
              )
              .toList(),
        ),
        if (_nextActionType != null && _nextActionType != NextActionType.none) ...[
          const SizedBox(height: 12),
          CompassDateField(
            label: 'When',
            value: _nextActionDate,
            onChanged: (v) => setState(() => _nextActionDate = v),
            firstDate: DateTime.now(),
            showTime: true,
          ),
        ],

        const SizedBox(height: 20),

        // ── Info banner just before Send so the user knows what
        // tapping Send actually does. ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF25D366)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Opens WhatsApp with this message pre-filled. Tap Send inside WhatsApp to deliver.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Primary action at the end — consistent with all other
        // logger sheets across the app. ──
        CompassButton(
          label: 'Send via WhatsApp',
          icon: Icons.send,
          isLoading: _sending,
          onPressed: canSend ? _send : null,
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _AttachmentChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFFE53935)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.close),
            color: AppColors.textHint,
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
