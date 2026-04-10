import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/send_back_sheet.dart';

class IbLeadDetailScreen extends StatefulWidget {
  final String ibLeadId;
  const IbLeadDetailScreen({super.key, required this.ibLeadId});

  @override
  State<IbLeadDetailScreen> createState() => _IbLeadDetailScreenState();
}

class _IbLeadDetailScreenState extends State<IbLeadDetailScreen> {
  final IbLeadRepository _repo = getIt<IbLeadRepository>();
  final NotificationService _notifications = getIt<NotificationService>();
  IbLeadModel? _lead;
  bool _isLoading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final lead = await _repo.getById(widget.ibLeadId);
    if (!mounted) return;
    setState(() {
      _lead = lead;
      _isLoading = false;
    });
  }

  Future<void> _approve() async {
    if (!mounted) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null || _lead == null) return;
    setState(() => _busy = true);
    final updated = await _repo.approve(
      _lead!.id,
      branchHeadId: user.id,
      branchHeadName: user.name,
    );
    if (!mounted) return;
    await _notifications.push(
      topic: 'rm-${updated.createdById}',
      notification: NotificationModel(
        id: 'NTF_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.ibLeadApproved,
        title: 'IB lead approved',
        body: '${updated.companyName} forwarded to IB team',
        deepLink: '/ib-leads/${updated.id}',
        createdAt: DateTime.now(),
        recipientUserId: updated.createdById,
      ),
    );
    if (!mounted) return;
    setState(() {
      _lead = updated;
      _busy = false;
    });
    if (!mounted) return;
    showCompassSnack(
      // ignore: use_build_context_synchronously
      context,
      message: 'Approved and forwarded to IB',
      type: CompassSnackType.success,
    );
  }

  Future<void> _sendBack() async {
    if (_lead == null) return;
    final remarks = await showSendBackSheet(context, _lead!.companyName);
    if (remarks == null) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    final updated = await _repo.sendBack(
      _lead!.id,
      branchHeadId: user.id,
      branchHeadName: user.name,
      remarks: remarks,
    );
    await _notifications.push(
      topic: 'rm-${updated.createdById}',
      notification: NotificationModel(
        id: 'NTF_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.ibLeadSentBack,
        title: 'IB lead returned',
        body: '${updated.companyName} sent back: $remarks',
        deepLink: '/ib-leads/${updated.id}',
        createdAt: DateTime.now(),
        recipientUserId: updated.createdById,
      ),
    );
    if (!mounted) return;
    setState(() {
      _lead = updated;
      _busy = false;
    });
    showCompassSnack(
      context,
      message: 'Returned to RM with remarks',
      type: CompassSnackType.warn,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _lead == null) {
      return const Scaffold(
        appBar: CompassAppBar(title: 'IB Lead'),
        body: CompassLoader(),
      );
    }

    final user = context.watch<AuthCubit>().state.currentUser;
    final isBranchHead =
        user?.role == UserRole.branchManager || user?.role == UserRole.admin;
    final isPending = _lead!.status == IbLeadStatus.pending;
    final canDecide = isBranchHead && isPending;

    final lead = _lead!;
    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: CompassAppBar(
        title: lead.companyName,
        subtitle: lead.dealType.label,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        children: [
          _statusBar(lead),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Client & Company'),
                const SizedBox(height: 10),
                if (lead.clientName != null) _row('Client', lead.clientName!),
                if (lead.clientCode != null) _row('Code', lead.clientCode!),
                _row('Company', lead.companyName),
                if (lead.contacts.isNotEmpty)
                  _row(
                    'Contacts',
                    lead.contacts.map((c) => '${c.name} (${c.designation})').join('\n'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Deal Details'),
                const SizedBox(height: 10),
                _row('Type', lead.dealTypeDisplay),
                _row(
                  'Value',
                  lead.dealValue != null
                      ? IndianCurrencyFormatter.shortForm(lead.dealValue!)
                      : lead.dealValueRange.label,
                ),
                _row('Stage', lead.dealStage.label),
                _row('Timeline', lead.timelineDisplay),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Context'),
                const SizedBox(height: 10),
                _row(
                  'Identified via',
                  lead.identifiedHow.map((h) => h.label).join(', '),
                ),
                if (lead.notes != null) _row('Notes', lead.notes!),
                if (lead.isConfidential)
                  _row('Confidential', 'Yes'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Audit'),
                const SizedBox(height: 10),
                _row('Created by', lead.createdByName),
                _row('Created at', _datetime(lead.createdAt)),
                if (lead.submittedAt != null)
                  _row('Submitted', _datetime(lead.submittedAt!)),
                if (lead.branchHeadName != null) _row('Reviewed by', lead.branchHeadName!),
                if (lead.decidedAt != null) _row('Decided at', _datetime(lead.decidedAt!)),
                if (lead.remarks != null)
                  _row('Remarks', lead.remarks!),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: canDecide
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surfacePrimary,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CompassButton.secondary(
                        label: 'Send Back',
                        onPressed: _busy ? null : _sendBack,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CompassButton(
                        label: 'Approve & Forward',
                        isLoading: _busy,
                        onPressed: _approve,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _statusBar(IbLeadModel lead) {
    final color = switch (lead.status) {
      IbLeadStatus.pending => AppColors.warmAmber,
      IbLeadStatus.approved => AppColors.successGreen,
      IbLeadStatus.sentBack => AppColors.errorRed,
      IbLeadStatus.forwarded => AppColors.tealAccent,
      IbLeadStatus.draft => AppColors.dormantGray,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(lead.status), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lead.status.label,
              style: AppTextStyles.labelLarge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(IbLeadStatus s) => switch (s) {
        IbLeadStatus.pending => Icons.hourglass_top,
        IbLeadStatus.approved => Icons.check_circle,
        IbLeadStatus.sentBack => Icons.replay,
        IbLeadStatus.forwarded => Icons.send,
        IbLeadStatus.draft => Icons.edit_note,
      };

  String _datetime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
