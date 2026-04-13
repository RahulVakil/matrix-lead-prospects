import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/enums/audit_action.dart';
import '../../../../core/enums/retention_status.dart';
import '../../../../core/models/audit_log_entry.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/next_action_model.dart';
import '../../../../core/models/timeline_entry_model.dart';
import '../../../../core/repositories/activity_repository.dart';
import '../../../../core/repositories/audit_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../activity/presentation/widgets/activity_quick_log_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../stage/presentation/widgets/mark_lost_sheet.dart';
import '../../../stage/presentation/widgets/stage_advance_sheet.dart';
import '../widgets/audit_trail_section.dart';
import '../widgets/data_export_sheet.dart';
import '../widgets/deletion_request_sheet.dart';
import '../widgets/edit_lead_sheet.dart';
import '../widgets/privacy_consent_section.dart';
import '../widgets/retention_banner.dart';
import '../../../stage/presentation/widgets/drop_lead_sheet.dart';

/// Lead Detail Hub — rebuilt to compass-real visual standard.
/// Navy hero header with identity built in, content sheet body where the
/// timeline is the visual anchor, single primary action at the bottom.
class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final LeadRepository _leadRepo = getIt<LeadRepository>();
  final ActivityRepository _activityRepo = getIt<ActivityRepository>();
  final AuditRepository _auditRepo = getIt<AuditRepository>();

  LeadModel? _lead;
  List<TimelineEntryModel> _timeline = const [];
  List<AuditLogEntry> _auditEntries = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final lead = await _leadRepo.getLeadById(widget.leadId);
      final timeline = await _leadRepo.getTimeline(widget.leadId);
      final audit = await _auditRepo.getForEntity('lead', widget.leadId);

      // Log PII view in audit trail
      final user = context.read<AuthCubit>().state.currentUser;
      if (user != null) {
        await _auditRepo.log(
          userId: user.id,
          userName: user.name,
          action: AuditAction.viewPII,
          entityType: 'lead',
          entityId: widget.leadId,
          details: 'Opened lead detail',
        );
      }

      if (!mounted) return;
      setState(() {
        _lead = lead;
        _timeline = timeline;
        _auditEntries = audit;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logActivity(ActivityType? preselected) async {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null || _lead == null) return;
    await ActivityQuickLogSheet.show(
      context,
      leadId: _lead!.id,
      leadName: _lead!.fullName,
      preselectedType: preselected,
      onSave: (type, notes, outcome, duration) async {
        await _activityRepo.logActivity(
          leadId: _lead!.id,
          type: type,
          dateTime: DateTime.now(),
          durationMinutes: duration,
          notes: notes,
          outcome: outcome,
          loggedById: user.id,
          loggedByName: user.name,
        );
        if (mounted) {
          showCompassSnack(context, message: 'Logged', type: CompassSnackType.success);
        }
        await _load();
      },
    );
  }

  Future<void> _advanceStage() async {
    if (_lead == null) return;
    await StageAdvanceSheet.show(
      context,
      currentStage: _lead!.stage,
      lead: _lead,
      onAdvance: (next, notes) async {
        await _leadRepo.updateLeadStage(_lead!.id, next, notes: notes);
        if (mounted) {
          showCompassSnack(
            context,
            message: 'Moved to ${next.label}',
            type: CompassSnackType.success,
          );
        }
        await _load();
      },
    );
  }

  Future<void> _parkOrClose() async {
    if (_lead == null) return;
    await MarkLostSheet.show(
      context,
      leadName: _lead!.fullName,
      onMarkLost: (reason, notes, reopenDate) async {
        await _leadRepo.markLost(_lead!.id, reason, notes: notes, reopenDate: reopenDate);
        if (mounted) {
          showCompassSnack(context, message: 'Marked lost', type: CompassSnackType.warn);
          context.pop();
        }
      },
      onPark: (reason, followUpDate, notes) async {
        await _leadRepo.parkLead(_lead!.id, reason, followUpDate, notes: notes);
        if (mounted) {
          showCompassSnack(
            context,
            message: 'Parked until ${followUpDate.day}/${followUpDate.month}',
            type: CompassSnackType.warn,
          );
          context.pop();
        }
      },
    );
  }

  Future<void> _clearNextAction() async {
    if (_lead == null) return;
    await _leadRepo.setNextAction(_lead!.id, null);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _lead == null) {
      return HeroScaffold(
        header: HeroAppBar.simple(title: 'Lead'),
        body: const Center(child: CompassLoader()),
      );
    }

    final lead = _lead!;
    final nextStage = lead.stage.nextStage;

    return HeroScaffold(
      header: _LeadHeroHeader(lead: lead, onMenu: _onMenuSelected),
      bottomBar: lead.stage.isTerminal
          ? null
          : _BottomActionBar(
              nextStageLabel: nextStage?.label,
              onPark: _parkOrClose,
              onAdvance: nextStage != null ? _advanceStage : null,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _SummaryStrip(lead: lead),
          const SizedBox(height: 18),
          if (lead.nextAction != null) ...[
            _NextActionCallout(action: lead.nextAction!, onClear: _clearNextAction),
            const SizedBox(height: 18),
          ],
          if (lead.retentionStatus != RetentionStatus.active)
            RetentionBanner(
              status: lead.retentionStatus,
              daysOverdue: DateTime.now()
                  .difference(lead.lastContactedAt ?? lead.createdAt)
                  .inDays,
              onExtend: () async {
                await _leadRepo.updateLead(lead.copyWith(
                  retentionStatus: RetentionStatus.retentionExtended,
                  lastContactedAt: DateTime.now(),
                ));
                showCompassSnack(context, message: 'Retention extended', type: CompassSnackType.success);
                await _load();
              },
              onDelete: () async {
                final confirmed = await showDeletionRequestSheet(context, lead.fullName);
                if (confirmed == true && mounted) {
                  await _leadRepo.updateLead(lead.copyWith(
                    retentionStatus: RetentionStatus.markedForDeletion,
                  ));
                  showCompassSnack(context, message: 'Deletion requested', type: CompassSnackType.warn);
                  await _load();
                }
              },
            ),
          _QuickActionGrid(
            onCall: () => _logActivity(ActivityType.call),
            onWhatsApp: () => _openWhatsApp(lead.phone),
            onMeet: () => _logActivity(ActivityType.meeting),
            onNote: () => _logActivity(ActivityType.note),
          ),
          const SizedBox(height: 24),
          if (lead.dealInfo != null) ...[
            _DealStrip(lead: lead),
            const SizedBox(height: 24),
          ],
          _SectionLabel('Activity', count: _timeline.length),
          const SizedBox(height: 12),
          _Timeline(entries: _timeline),
          const SizedBox(height: 24),
          _DetailsBlock(lead: lead),
          const SizedBox(height: 12),
          PrivacyConsentSection(
            status: lead.consentStatus,
            records: lead.consentRecords,
            onRecordConsent: () {
              showCompassSnack(context, message: 'Consent recorded', type: CompassSnackType.success);
            },
            onRevokeConsent: () {
              showCompassSnack(context, message: 'Consent revoked — lead flagged for deletion', type: CompassSnackType.warn);
            },
          ),
          const SizedBox(height: 12),
          AuditTrailSection(entries: _auditEntries),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final waNum = digits.startsWith('91') ? digits : '91$digits';
    final uri = Uri.parse('https://wa.me/$waNum');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    // After returning from WhatsApp, prompt to log the activity
    if (mounted) {
      _logActivity(ActivityType.whatsApp);
    }
  }

  Future<void> _editLead() async {
    if (_lead == null) return;
    final updated = await showEditLeadSheet(context, _lead!);
    if (updated != null && mounted) {
      await _leadRepo.updateLead(updated);
      showCompassSnack(context, message: 'Details updated', type: CompassSnackType.success);
      await _load();
    }
  }

  Future<void> _exportData() async {
    if (_lead == null) return;
    final user = context.read<AuthCubit>().state.currentUser;
    if (user != null) {
      await _auditRepo.log(
        userId: user.id,
        userName: user.name,
        action: AuditAction.exportData,
        entityType: 'lead',
        entityId: _lead!.id,
      );
    }
    if (mounted) await showDataExportSheet(context, _lead!);
  }

  Future<void> _requestDeletion() async {
    if (_lead == null) return;
    final confirmed = await showDeletionRequestSheet(context, _lead!.fullName);
    if (confirmed == true && mounted) {
      await _leadRepo.updateLead(_lead!.copyWith(
        retentionStatus: RetentionStatus.markedForDeletion,
      ));
      final user = context.read<AuthCubit>().state.currentUser;
      if (user != null) {
        await _auditRepo.log(
          userId: user.id,
          userName: user.name,
          action: AuditAction.deletePII,
          entityType: 'lead',
          entityId: _lead!.id,
        );
      }
      if (mounted) {
        showCompassSnack(context, message: 'Deletion requested', type: CompassSnackType.warn);
        context.pop();
      }
    }
  }

  Future<void> _dropLead() async {
    if (_lead == null) return;
    await DropLeadSheet.show(
      context,
      leadName: _lead!.fullName,
      onDrop: (reason, notes) async {
        final user = context.read<AuthCubit>().state.currentUser;
        if (user == null) return;
        await _leadRepo.dropLead(
          _lead!.id,
          reason: reason,
          notes: notes,
          droppedByUserId: user.id,
        );
        if (mounted) {
          showCompassSnack(context, message: 'Lead dropped', type: CompassSnackType.warn);
          context.pop();
        }
      },
    );
  }

  void _onMenuSelected(String value) {
    final lead = _lead;
    if (lead == null) return;
    switch (value) {
      case 'ib':
        context.push('/ib-leads/new', extra: {
          'clientName': lead.fullName,
          'companyName': lead.companyName,
        });
        break;
      case 'edit':
        _editLead();
        break;
      case 'drop':
        _dropLead();
        break;
      case 'export':
        _exportData();
        break;
      case 'delete':
        _requestDeletion();
        break;
      case 'park':
        _parkOrClose();
        break;
    }
  }
}

// ────────────────────────────────────────────────────────────────────
// Hero header — full identity in the navy block
// ────────────────────────────────────────────────────────────────────

class _LeadHeroHeader extends StatelessWidget {
  final LeadModel lead;
  final ValueChanged<String> onMenu;

  const _LeadHeroHeader({required this.lead, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.heroBackdrop,
      padding: EdgeInsets.fromLTRB(8, topInset + 4, 8, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).maybePop(),
                splashRadius: 22,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                onSelected: onMenu,
                position: PopupMenuPosition.under,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined, size: 20),
                      title: Text('Edit details'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ib',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.business_center_outlined, size: 20),
                      title: Text('Capture IB Lead'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.download_outlined, size: 20),
                      title: Text('Export data'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'drop',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.remove_circle_outline, size: 20, color: Colors.orange),
                      title: Text('Drop lead'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'park',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.pause_circle_outline, size: 20),
                      title: Text('Park / Close'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      title: Text('Request deletion'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroAvatar(name: lead.fullName, temperatureColor: lead.temperature.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.fullName,
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lead.companyName ?? lead.phone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _HeroChip(
                            color: lead.temperature.color,
                            label: lead.temperature.label,
                          ),
                          const SizedBox(width: 6),
                          _HeroChip(
                            color: lead.stage.color,
                            label: lead.stage.label,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String name;
  final Color temperatureColor;

  const _HeroAvatar({required this.name, required this.temperatureColor});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.navyPrimary,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: temperatureColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.heroBackdrop, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final Color color;
  final String label;

  const _HeroChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Summary strip — owner / last contact / score in one inline row
// ────────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final LeadModel lead;
  const _SummaryStrip({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _summaryCell(
          icon: Icons.person_outline,
          label: 'Owner',
          value: lead.assignedRmName.split(' ').first,
        ),
        _divider(),
        _summaryCell(
          icon: Icons.schedule,
          label: 'Last contact',
          value: lead.lastContactDisplay,
        ),
        _divider(),
        _summaryCell(
          icon: Icons.bolt_outlined,
          label: 'Score',
          value: '${lead.score}',
          accent: lead.temperature.color,
        ),
      ],
    );
  }

  Widget _summaryCell({
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: accent ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.borderDefault.withValues(alpha: 0.6),
      );
}

// ────────────────────────────────────────────────────────────────────
// Next-action callout — coloured by urgency, prominent
// ────────────────────────────────────────────────────────────────────

class _NextActionCallout extends StatelessWidget {
  final NextActionModel action;
  final VoidCallback onClear;

  const _NextActionCallout({required this.action, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final color = action.isOverdue
        ? AppColors.errorRed
        : action.isDueSoon
            ? AppColors.warmAmber
            : AppColors.tealAccent;

    final urgencyLabel = action.isOverdue
        ? 'OVERDUE'
        : action.isDueSoon
            ? 'DUE SOON'
            : 'SCHEDULED';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(action.type.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  urgencyLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.dueDisplay,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (action.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    action.notes!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textHint,
            onPressed: onClear,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Quick action grid — 4 tiles, square, generous, primary affordances
// ────────────────────────────────────────────────────────────────────

class _QuickActionGrid extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMeet;
  final VoidCallback onNote;

  const _QuickActionGrid({
    required this.onCall,
    required this.onWhatsApp,
    required this.onMeet,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(Icons.phone_outlined, 'Call', AppColors.successGreen, onCall),
        const SizedBox(width: 10),
        _tile(Icons.chat_bubble_outline, 'WhatsApp', const Color(0xFF25D366), onWhatsApp),
        const SizedBox(width: 10),
        _tile(Icons.event_outlined, 'Meet', AppColors.navyPrimary, onMeet),
        const SizedBox(width: 10),
        _tile(Icons.edit_note, 'Note', AppColors.warmAmber, onNote),
      ],
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Deal strip — single inline row of key deal facts
// ────────────────────────────────────────────────────────────────────

class _DealStrip extends StatelessWidget {
  final LeadModel lead;
  const _DealStrip({required this.lead});

  @override
  Widget build(BuildContext context) {
    final d = lead.dealInfo!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.navyPrimary),
              const SizedBox(width: 6),
              Text(
                'DEAL',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (d.expectedCloseMonth != null)
                Text(
                  'Close ${d.expectedCloseMonth}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                IndianCurrencyFormatter.shortForm(d.aumEstimate),
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.navyPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _probability(d.probability),
              ),
            ],
          ),
          if (d.products.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: d.products
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfacePrimary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Text(
                          p,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _probability(int probability) {
    final color = probability >= 70
        ? AppColors.successGreen
        : probability >= 40
            ? AppColors.warmAmber
            : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$probability% likely',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Section label
// ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionLabel(this.title, {this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '· $count',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Timeline — DOMINANT element. Real timeline rail, not stacked rows.
// ────────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<TimelineEntryModel> entries;
  const _Timeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No activity yet — tap Call, WhatsApp, Meet or Note above',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final visible = entries.take(12).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: List.generate(visible.length, (i) {
          return _TimelineRow(
            entry: visible[i],
            isFirst: i == 0,
            isLast: i == visible.length - 1,
          );
        }),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEntryModel entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail with dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                SizedBox(
                  height: isFirst ? 4 : 0,
                  child: const SizedBox.shrink(),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: entry.type.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.type.icon, size: 14, color: entry.type.color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppColors.borderDefault.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, isFirst ? 4 : 0, 0, isLast ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.dateDisplay} · ${entry.timeDisplay}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                  if (entry.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (entry.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Details block — collapsed by default
// ────────────────────────────────────────────────────────────────────

class _DetailsBlock extends StatefulWidget {
  final LeadModel lead;
  const _DetailsBlock({required this.lead});

  @override
  State<_DetailsBlock> createState() => _DetailsBlockState();
}

class _DetailsBlockState extends State<_DetailsBlock>
    with SingleTickerProviderStateMixin {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.lead;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'DETAILS',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _row('Phone', l.phone),
                        if (l.email != null) _row('Email', l.email!),
                        _row('Source', l.source.label),
                        if (l.productInterest.isNotEmpty)
                          _row('Products', l.productInterest.join(', ')),
                        if (l.companyName != null) _row('Company', l.companyName!),
                        if (l.city != null) _row('City', l.city!),
                        if (l.estimatedAum != null) _row('Est. AUM', l.aumDisplay),
                        _row('Vertical', l.vertical),
                        _row('Owner', l.assignedRmName),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bottom action bar
// ────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final String? nextStageLabel;
  final VoidCallback onPark;
  final VoidCallback? onAdvance;

  const _BottomActionBar({
    required this.nextStageLabel,
    required this.onPark,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          border: Border(
            top: BorderSide(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: onPark,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              child: const Text('Park / Close'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CompassButton(
                label: nextStageLabel != null
                    ? 'Advance to $nextStageLabel'
                    : 'Converted',
                onPressed: onAdvance,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
