import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/ib_deal_type.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/models/ib_lead_model.dart';
import '../../../../core/models/ib_progress_update.dart';
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
import '../widgets/mis_assignment_sheet.dart';
import '../widgets/progress_update_sheet.dart';
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
    // Admin / MIS now explicitly picks the IB RM + CC list before approving.
    final assignment = await showMisAssignmentSheet(
      context,
      dealType: _lead!.dealType,
      companyLabel: _lead!.companyName,
    );
    if (assignment == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final approved = await _repo.approve(
      _lead!.id,
      branchHeadId: user.id,
      branchHeadName: user.name,
    );
    final assigned = approved.copyWith(
      assignedIbRmId: assignment.ibRm.id,
      assignedIbRmName: assignment.ibRm.name,
      assignedAt: DateTime.now(),
      assignmentCcList: assignment.ccList,
    );
    await _repo.saveDraft(assigned); // upserts via _put
    if (!mounted) return;
    await _notifications.push(
      topic: 'rm-${assigned.createdById}',
      notification: NotificationModel(
        id: 'NTF_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.ibLeadApproved,
        title: 'IB lead approved',
        body:
            '${assigned.companyName} assigned to ${assignment.ibRm.name}',
        deepLink: '/ib-leads/${assigned.id}',
        createdAt: DateTime.now(),
        recipientUserId: assigned.createdById,
      ),
    );
    if (!mounted) return;
    setState(() {
      _lead = assigned;
      _busy = false;
    });
    showCompassSnack(
      // ignore: use_build_context_synchronously
      context,
      message: 'Approved — assigned to ${assignment.ibRm.name}',
      type: CompassSnackType.success,
    );
  }

  Future<void> _logProgress() async {
    if (_lead == null) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) return;
    final update = await showProgressUpdateSheet(
      context,
      authorId: user.id,
      authorName: user.name,
      currentStatus: _lead!.latestProgressStatus,
    );
    if (update == null) return;
    final next = _lead!.copyWith(
      progressUpdates: [..._lead!.progressUpdates, update],
    );
    await _repo.saveDraft(next);
    if (!mounted) return;
    setState(() => _lead = next);
    showCompassSnack(
      context,
      message: 'Status update saved',
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
    // Only Admin / MIS can approve or send back. IB user reads only.
    final isReviewer = user?.role == UserRole.admin;
    final isPending = _lead!.status.isAwaitingReview;
    final canDecide = isReviewer && isPending;

    final lead = _lead!;
    final isCreator = user?.id == lead.createdById;
    final canLogProgress = isCreator && lead.status.isApproved;
    // Confidential mask for non-creator + non-admin when lead is not yet
    // assigned (prototype approximation of the DPDP-style restriction).
    final maskIdentity = lead.isConfidential &&
        !isCreator &&
        user?.role != UserRole.teamLead &&
        lead.assignedIbRmId == null;
    final companyLabel = maskIdentity
        ? 'Confidential lead · #${lead.id}'
        : lead.companyName;

    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: CompassAppBar(
        title: companyLabel,
        subtitle: lead.dealType.label,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        children: [
          _statusBar(lead),
          if (lead.isProgressOverdue && canLogProgress) ...[
            const SizedBox(height: 10),
            _OverdueBanner(days: lead.daysSinceLastProgress),
          ],
          if (lead.isConfidential) ...[
            const SizedBox(height: 10),
            _ConfidentialBanner(reason: lead.confidentialReason),
          ],
          if (lead.assignedIbRmName != null) ...[
            const SizedBox(height: 12),
            _AssignedCard(lead: lead),
          ],
          const SizedBox(height: 12),
          CompassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompassSectionHeader(title: 'Client & Company'),
                const SizedBox(height: 10),
                if (maskIdentity)
                  _row('Company', 'Hidden until assignment')
                else ...[
                  if (lead.clientName != null) _row('Client', lead.clientName!),
                  if (lead.clientCode != null) _row('Code', lead.clientCode!),
                  _row('Company', lead.companyName),
                  if (lead.contacts.isNotEmpty)
                    _row(
                      'Contacts',
                      lead.contacts.map((c) => '${c.name} (${c.designation})').join('\n'),
                    ),
                ],
                if (lead.industry != null) _row('Industry', lead.industryDisplay),
                if ((lead.websiteUrl ?? '').isNotEmpty)
                  _row('Website', lead.websiteUrl!),
                if (lead.financialDocs.isNotEmpty)
                  _row('Financial docs',
                      '${lead.financialDocs.length} file${lead.financialDocs.length == 1 ? '' : 's'} attached'),
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
                _row('Stage', lead.dealStage?.label ?? '—'),
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
          if (lead.status.isApproved && lead.assignedIbRmName != null) ...[
            const SizedBox(height: 12),
            _ProgressCard(
              lead: lead,
              canLog: canLogProgress,
              onLog: _logProgress,
            ),
          ],
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
      IbLeadStatus.forwarded => AppColors.successGreen,
      IbLeadStatus.draft => AppColors.warmAmber,
      IbLeadStatus.dropped => AppColors.dormantGray,
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
        IbLeadStatus.forwarded => Icons.check_circle,
        IbLeadStatus.draft => Icons.hourglass_top,
        IbLeadStatus.dropped => Icons.cancel_outlined,
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

// ────────────────────────────────────────────────────────────────────
// Supporting blocks for the detail screen
// ────────────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  final int days;
  const _OverdueBanner({required this.days});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Status update overdue — $days days since last update. '
              'Update now to stay compliant with the 30-day cycle.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidentialBanner extends StatelessWidget {
  final String? reason;
  const _ConfidentialBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppColors.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (reason ?? '').isEmpty
                  ? 'Marked Confidential by the originating RM.'
                  : 'Confidential — ${reason!}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedCard extends StatelessWidget {
  final IbLeadModel lead;
  const _AssignedCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return CompassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompassSectionHeader(title: 'Assignment'),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person_outline,
                    color: AppColors.navyPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.assignedIbRmName ?? '—',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      lead.assignedAt != null
                          ? 'Assigned on ${lead.assignedAt!.day}/${lead.assignedAt!.month}/${lead.assignedAt!.year}'
                          : 'Assigned',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lead.assignmentCcList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Email CC',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lead.assignmentCcList
                  .map((e) => Chip(
                        label: Text(e, style: AppTextStyles.caption),
                        backgroundColor: AppColors.surfaceTertiary,
                        side: BorderSide(color: AppColors.borderDefault),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final IbLeadModel lead;
  final bool canLog;
  final VoidCallback onLog;
  const _ProgressCard({
    required this.lead,
    required this.canLog,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return CompassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: CompassSectionHeader(title: 'Status updates (30-day cycle)'),
              ),
              if (canLog)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onLog,
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (lead.progressUpdates.isEmpty)
            Text(
              'No updates yet. The RM owes a first update within 30 days of assignment.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            ...lead.progressUpdates.reversed.map(
              (u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: BoxDecoration(
                        color: u.status.isClosed
                            ? (u.status == IbProgressStatus.closedWon
                                ? AppColors.successGreen
                                : AppColors.errorRed)
                            : AppColors.navyPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                u.status.label,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${u.createdAt.day}/${u.createdAt.month}/${u.createdAt.year}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textHint),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(u.notes, style: AppTextStyles.bodySmall),
                          Text(
                            '— ${u.authorName}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
