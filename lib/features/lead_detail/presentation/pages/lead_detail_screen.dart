import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/next_action_model.dart';
import '../../../../core/models/timeline_entry_model.dart';
import '../../../../core/repositories/activity_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/compass_app_bar.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_card.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_section_header.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/stage_badge.dart';
import '../../../../core/widgets/temp_pill.dart';
import '../../../activity/presentation/widgets/activity_quick_log_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../stage/presentation/widgets/mark_lost_sheet.dart';
import '../../../stage/presentation/widgets/stage_advance_sheet.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final LeadRepository _leadRepo = getIt<LeadRepository>();
  final ActivityRepository _activityRepo = getIt<ActivityRepository>();

  LeadModel? _lead;
  List<TimelineEntryModel> _timeline = const [];
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
      if (!mounted) return;
      setState(() {
        _lead = lead;
        _timeline = timeline;
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
          showCompassSnack(
            context,
            message: 'Activity logged',
            type: CompassSnackType.success,
          );
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
          showCompassSnack(
            context,
            message: 'Lead marked as lost',
            type: CompassSnackType.warn,
          );
          context.pop();
        }
      },
      onPark: (reason, followUpDate, notes) async {
        await _leadRepo.parkLead(_lead!.id, reason, followUpDate, notes: notes);
        if (mounted) {
          showCompassSnack(
            context,
            message: 'Lead parked until ${followUpDate.day}/${followUpDate.month}',
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
    showCompassSnack(context, message: 'Next action cleared');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _lead == null) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceTertiary,
        appBar: CompassAppBar(title: 'Lead'),
        body: CompassLoader(),
      );
    }

    final lead = _lead!;
    final nextStage = lead.stage.nextStage;

    return Scaffold(
      backgroundColor: AppColors.surfaceTertiary,
      appBar: CompassAppBar(
        title: lead.fullName,
        subtitle: lead.companyName,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'ib':
                  context.push('/ib-leads/new', extra: {
                    'clientName': lead.fullName,
                    'companyName': lead.companyName,
                  });
                  break;
                case 'park':
                  _parkOrClose();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ib', child: Text('Capture IB Lead')),
              PopupMenuItem(value: 'park', child: Text('Park / Close')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        children: [
          _HeaderCard(lead: lead),
          if (lead.nextAction != null) ...[
            const SizedBox(height: 12),
            _NextActionBanner(
              action: lead.nextAction!,
              onClear: _clearNextAction,
            ),
          ],
          const SizedBox(height: 12),
          _QuickActionRow(
            onCall: () => _logActivity(ActivityType.call),
            onWhatsApp: () => _logActivity(ActivityType.whatsApp),
            onMeet: () => _logActivity(ActivityType.meeting),
            onNote: () => _logActivity(ActivityType.note),
          ),
          const SizedBox(height: 12),
          if (lead.dealInfo != null) ...[
            _DealInfoCard(lead: lead),
            const SizedBox(height: 12),
          ],
          _TimelineCard(entries: _timeline),
          const SizedBox(height: 12),
          _DetailsCard(lead: lead),
        ],
      ),
      bottomNavigationBar: lead.stage.isTerminal
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surfacePrimary,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CompassButton.secondary(
                        label: 'Park / Close',
                        onPressed: _parkOrClose,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: CompassButton(
                        label: nextStage != null
                            ? 'Advance to ${nextStage.label}'
                            : 'Converted',
                        onPressed: nextStage != null ? _advanceStage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final LeadModel lead;
  const _HeaderCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return CompassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AvatarCircle(name: lead.fullName, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lead.fullName, style: AppTextStyles.heading3),
                if (lead.phone.isNotEmpty)
                  Text(lead.phone, style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    TempPill(temperature: lead.temperature),
                    StageBadge(stage: lead.stage),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${lead.assignedRmName} · ${lead.lastContactDisplay}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActionBanner extends StatelessWidget {
  final NextActionModel action;
  final VoidCallback onClear;

  const _NextActionBanner({required this.action, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final color = action.isOverdue
        ? AppColors.errorRed
        : action.isDueSoon
            ? AppColors.warmAmber
            : AppColors.navyPrimary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(action.type.icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action.dueDisplay,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
                if (action.notes != null)
                  Text(action.notes!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMeet;
  final VoidCallback onNote;

  const _QuickActionRow({
    required this.onCall,
    required this.onWhatsApp,
    required this.onMeet,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _qa(Icons.phone, 'Call', onCall),
        const SizedBox(width: 8),
        _qa(Icons.chat_bubble_outline, 'WhatsApp', onWhatsApp),
        const SizedBox(width: 8),
        _qa(Icons.event, 'Meet', onMeet),
        const SizedBox(width: 8),
        _qa(Icons.note_alt_outlined, 'Note', onNote),
      ],
    );
  }

  Widget _qa(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.navyPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, size: 20, color: AppColors.navyPrimary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.navyPrimary,
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

class _DealInfoCard extends StatelessWidget {
  final LeadModel lead;
  const _DealInfoCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final d = lead.dealInfo!;
    return CompassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CompassSectionHeader(title: 'Deal Info'),
          const SizedBox(height: 10),
          _row('Estimated AUM', IndianCurrencyFormatter.shortForm(d.aumEstimate)),
          if (d.products.isNotEmpty) _row('Products', d.products.join(', ')),
          if (d.expectedCloseMonth != null) _row('Expected close', d.expectedCloseMonth!),
          _row('Probability', '${d.probability}%'),
        ],
      ),
    );
  }

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

class _TimelineCard extends StatelessWidget {
  final List<TimelineEntryModel> entries;
  const _TimelineCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return CompassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompassSectionHeader(title: 'Activity', count: entries.length),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No activity yet — tap Call, WhatsApp, Meet or Note above to log',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            ...entries.take(20).map((e) => _row(e)),
        ],
      ),
    );
  }

  Widget _row(TimelineEntryModel e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: e.type.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(e.type.icon, size: 16, color: e.type.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.title,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${e.dateDisplay} · ${e.timeDisplay}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                if (e.subtitle != null)
                  Text(e.subtitle!, style: AppTextStyles.bodySmall),
                if (e.notes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      e.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textBody,
                      ),
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

class _DetailsCard extends StatefulWidget {
  final LeadModel lead;
  const _DetailsCard({required this.lead});

  @override
  State<_DetailsCard> createState() => _DetailsCardState();
}

class _DetailsCardState extends State<_DetailsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.lead;
    return CompassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Expanded(child: CompassSectionHeader(title: 'Details')),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _row('Phone', l.phone),
                  if (l.email != null) _row('Email', l.email!),
                  _row('Source', l.source.label),
                  if (l.productInterest.isNotEmpty)
                    _row('Products', l.productInterest.join(', ')),
                  if (l.companyName != null) _row('Company', l.companyName!),
                  if (l.city != null) _row('City', l.city!),
                  if (l.estimatedAum != null) _row('Est. AUM', l.aumDisplay),
                  _row('Owner', l.assignedRmName),
                  _row('Vertical', l.vertical),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
