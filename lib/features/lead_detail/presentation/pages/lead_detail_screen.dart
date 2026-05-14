import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/activity_type.dart';
import '../../../../core/enums/audit_action.dart';
import '../../../../core/enums/next_action_type.dart';
import '../../../../core/enums/retention_status.dart';
import '../../../../core/models/activity_model.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/models/next_action_model.dart';
import '../../../../core/models/timeline_entry_model.dart';
import '../../../../core/repositories/activity_repository.dart';
import '../../../../core/repositories/audit_repository.dart';
import '../../../../core/repositories/ib_lead_repository.dart';
import '../../../../core/repositories/lead_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/duplicate_ib_check.dart';
import '../../../../core/utils/inr_formatter.dart';
import '../../../../core/utils/pii_display.dart';
import '../../../../core/widgets/compass_button.dart';
import '../../../../core/widgets/compass_loader.dart';
import '../../../../core/widgets/compass_snackbar.dart';
import '../../../../core/widgets/hero_app_bar.dart';
import '../../../../core/widgets/hero_scaffold.dart';
import '../../../activity/presentation/widgets/activity_quick_log_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../stage/presentation/widgets/mark_lost_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/enums/user_role.dart';
import '../widgets/call_action_chooser_sheet.dart';
import '../widgets/call_logs_viewer_sheet.dart';
import '../widgets/meeting_logs_viewer_sheet.dart';
import '../widgets/note_logs_viewer_sheet.dart';
import '../widgets/tl_call_chooser_sheet.dart';
import '../widgets/tl_meeting_chooser_sheet.dart';
import '../widgets/meeting_action_chooser_sheet.dart';
import '../widgets/meeting_picker_sheet.dart';
import '../widgets/data_export_sheet.dart';
import '../widgets/deletion_request_sheet.dart';
import '../widgets/convert_to_ib_sheet.dart';
import '../widgets/edit_lead_sheet.dart';
import '../widgets/meeting_create_sheet.dart';
import '../widgets/retention_banner.dart';
import '../widgets/whatsapp_composer_sheet.dart';
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

      // PII view still recorded in the audit log (no UI surface, but kept
      // for compliance plumbing — DPDP-PII privacy ticket consumes it).
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
      onSave: (type, notes, outcome, duration, nextActionType, nextActionDate) async {
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
        await _persistNextAction(nextActionType, nextActionDate);
        if (mounted) {
          showCompassSnack(context, message: 'Logged', type: CompassSnackType.success);
        }
        await _load();
        // Chain into the meeting create flow when the chosen follow-up
        // is a meeting — RM gets to capture title/link/mode without
        // re-tapping into a separate sheet later.
        if (mounted &&
            nextActionType == NextActionType.meeting &&
            nextActionDate != null) {
          await _chainFollowUpMeeting(nextActionDate, user);
        }
      },
    );
  }

  /// Persist the next-action chip on the lead. Called from every action
  /// surface (Call log, WhatsApp composer, Meeting sheet) so each follows
  /// the same persistence path.
  Future<void> _persistNextAction(
    NextActionType? type,
    DateTime? date,
  ) async {
    if (_lead == null) return;
    if (type == null || type == NextActionType.none) return;
    await _leadRepo.setNextAction(
      _lead!.id,
      NextActionModel(type: type, dueAt: date),
    );
  }

  /// Open the MeetingCreateSheet pre-loaded with the next-action date.
  /// Logs the resulting future meeting as an activity entry. The sheet
  /// hides its own next-action picker to avoid recursion.
  Future<void> _chainFollowUpMeeting(
    DateTime when,
    user,
  ) async {
    if (_lead == null) return;
    final result = await MeetingCreateSheet.show(
      context,
      leadName: _lead!.fullName,
      prefilledWhen: when,
      hideNextAction: true,
    );
    if (!mounted || result == null) return;
    final isFuture = result.when.isAfter(DateTime.now());
    await _activityRepo.logActivity(
      leadId: _lead!.id,
      type: ActivityType.meeting,
      dateTime: result.when,
      durationMinutes: result.durationMinutes,
      notes: result.toLogNotes(),
      outcome: isFuture ? ActivityOutcome.followUp : ActivityOutcome.completed,
      loggedById: user.id,
      loggedByName: user.name,
    );
    if (mounted) {
      showCompassSnack(
        context,
        message: 'Follow-up meeting scheduled',
        type: CompassSnackType.success,
      );
      await _load();
    }
  }

  /// Push the RM-Assisted Onboarding journey for this lead. The submitted
  /// onboarding form stamps stage = LeadStage.onboard and writes a
  /// structured one-liner into notes.
  Future<void> _onboard() async {
    if (_lead == null) return;
    await context.push('/leads/${_lead!.id}/onboard');
    if (mounted) await _load();
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

    final isTlView = _isTlView;

    return HeroScaffold(
      header: _LeadHeroHeader(
        lead: lead,
        onMenu: _onMenuSelected,
        isTlView: isTlView,
      ),
      // Bottom bar (Drop + Onboard) is hidden for TL view — TL has no
      // state-change rights on a reportee's lead.
      bottomBar: (lead.stage.isTerminal || isTlView)
          ? null
          : _BottomActionBar(
              onDrop: _dropLead,
              onOnboard: _onboard,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          if (isTlView) ...[
            _TlReadOnlyBanner(rmName: lead.assignedRmName),
            const SizedBox(height: 14),
          ],
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
            onCall: _onCallTap,
            // WhatsApp tile is dormant when no phone is on file (wealth Add
            // Lead allows phone-less entries — email-only / walk-in leads).
            onWhatsApp: (lead.phone == null || lead.phone!.isEmpty)
                ? null
                : _onWhatsappTap,
            onMeet: _onMeetTap,
            onNote: _onNoteTap,
          ),
          const SizedBox(height: 16),

          // IB convert CTA — hidden for TL view (TL can't initiate
          // state changes on a reportee's lead). The "already converted"
          // info card stays visible for context.
          if (lead.ibLeadIds.isEmpty && !isTlView)
            _IbConvertCard(onTap: () => _onMenuSelected('ib'))
          else if (lead.ibLeadIds.isNotEmpty)
            _IbConvertedInfo(ibLeadId: lead.ibLeadIds.first),
          const SizedBox(height: 16),

          if (lead.dealInfo != null) ...[
            _DealStrip(lead: lead),
            const SizedBox(height: 24),
          ],
          _SectionLabel('Activity', count: _timeline.length),
          const SizedBox(height: 12),
          _Timeline(entries: _timeline),
          const SizedBox(height: 24),
          _DetailsBlock(lead: lead),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  // ── Call ─────────────────────────────────────────────────────────
  // Call tile opens a chooser: dial-and-log or log-only. Dialer launch
  // uses tel:; on return we auto-open the log sheet preselected to call.

  /// True when the current viewer is a Team Lead looking at a lead that
  /// belongs to a reportee (i.e. not the TL's own lead). In this mode the
  /// TL gets read-only access — no logging on the RM's behalf.
  bool get _isTlView {
    final user = context.read<AuthCubit>().state.currentUser;
    final lead = _lead;
    if (user == null || lead == null) return false;
    return user.role == UserRole.teamLead &&
        lead.assignedRmId != user.id;
  }

  Future<void> _onCallTap() async {
    final lead = _lead;
    if (lead == null) return;

    // Team Lead viewing a reportee's lead → "Call now" or "View call logs".
    // No "Log past call" path: TL cannot log on the RM's behalf.
    if (_isTlView) {
      final loggedCalls =
          await _activityRepo.getActivitiesForLead(lead.id);
      final callCount = loggedCalls
          .where((a) => a.type == ActivityType.call)
          .length;
      if (!mounted) return;
      final choice = await TlCallChooserSheet.show(
        context,
        leadName: lead.fullName,
        phone: lead.phone,
        loggedCallCount: callCount,
      );
      if (!mounted || choice == null) return;
      switch (choice) {
        case TlCallChoice.callNow:
          if (lead.phone == null || lead.phone!.isEmpty) return;
          final ok =
              await CallActionChooserSheet.launchDialer(lead.phone!);
          if (!mounted) return;
          if (!ok) {
            showCompassSnack(context,
                message: 'Couldn\'t open the dialer.',
                type: CompassSnackType.warn);
          }
          // Intentionally NO log prompt on return — TL can't log on
          // the RM's behalf.
          break;
        case TlCallChoice.viewLogs:
          await CallLogsViewerSheet.show(
            context,
            leadName: lead.fullName,
            activities: loggedCalls,
          );
          break;
      }
      return;
    }

    // Default flow — RM (lead owner) flow with the existing chooser
    // (Call now / Log a past call) and auto-log on return.
    final choice = await CallActionChooserSheet.show(
      context,
      leadName: lead.fullName,
      phone: lead.phone,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case CallChoice.callNow:
        if (lead.phone == null || lead.phone!.isEmpty) return;
        final ok = await CallActionChooserSheet.launchDialer(lead.phone!);
        if (!mounted) return;
        if (!ok) {
          showCompassSnack(context,
              message: 'Couldn\'t open the dialer.', type: CompassSnackType.warn);
          return;
        }
        // After return from dialer, prompt to log details.
        await _logActivity(ActivityType.call);
        break;
      case CallChoice.logPast:
        await _logActivity(ActivityType.call);
        break;
    }
  }

  // ── WhatsApp ─────────────────────────────────────────────────────
  // WhatsApp tile opens the composer directly. Every send auto-logs the
  // activity, so a separate "log a past WhatsApp" path was redundant —
  // for messages sent outside the app, the Note tile is the right home.

  Future<void> _onWhatsappTap() async {
    final lead = _lead;
    if (lead == null) return;

    // TL viewing reportee → just launch wa.me with the lead's phone.
    // No composer, no log creation — TL has no log rights on RM's lead.
    if (_isTlView) {
      if (lead.phone == null || lead.phone!.isEmpty) return;
      final digits = lead.phone!.replaceAll(RegExp(r'[^\d+]'), '');
      final waUrl = Uri.parse(
          'https://wa.me/${digits.replaceFirst(RegExp(r'^\+'), '')}');
      final ok = await launchUrl(waUrl,
          mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        showCompassSnack(context,
            message: "Couldn't open WhatsApp.",
            type: CompassSnackType.warn);
      }
      return;
    }

    // Default flow — RM (lead owner) opens composer with auto-log on send.
    return _openWhatsappComposer();
  }

  /// Opens the composer; on Send launches wa.me with the message
  /// pre-filled, logs the activity (with message body + attachments in
  /// notes), persists the next action, and chains a follow-up meeting
  /// when the RM picked Meeting as the next action.
  Future<void> _openWhatsappComposer() async {
    final lead = _lead;
    final user = context.read<AuthCubit>().state.currentUser;
    if (lead == null || user == null) return;
    if (lead.phone == null || lead.phone!.isEmpty) return;

    // Take the first token of the full name as a "first name" for the
    // template substitution. Good enough for the prototype; production
    // should use the canonical first-name field on the lead.
    final firstName = lead.fullName.trim().split(RegExp(r'\s+')).first;

    final result = await WhatsappComposerSheet.show(
      context,
      leadName: lead.fullName,
      leadFirstName: firstName,
      rmName: user.name,
      phone: lead.phone!,
    );
    if (!mounted || result == null) return;

    final notesBuf = StringBuffer('[${result.templateKey}] ${result.message}');
    if (result.attachmentNames.isNotEmpty) {
      notesBuf.write('\nAttached: ${result.attachmentNames.join(", ")}');
    }
    await _activityRepo.logActivity(
      leadId: lead.id,
      type: ActivityType.whatsApp,
      dateTime: DateTime.now(),
      notes: notesBuf.toString(),
      outcome: ActivityOutcome.completed,
      loggedById: user.id,
      loggedByName: user.name,
    );

    await _persistNextAction(result.nextActionType, result.nextActionDate);

    if (mounted) {
      showCompassSnack(context,
          message: 'WhatsApp sent and logged',
          type: CompassSnackType.success);
      await _load();
    }
    if (mounted &&
        result.nextActionType == NextActionType.meeting &&
        result.nextActionDate != null) {
      await _chainFollowUpMeeting(result.nextActionDate!, user);
    }
  }

  // ── Meeting ──────────────────────────────────────────────────────
  // Meet tile opens a chooser: schedule-new or log-past — same pattern
  // as Call. Schedule-new opens the meeting create form; log-past goes
  // straight to the activity log sheet preselected to meeting.

  Future<void> _onMeetTap() async {
    final lead = _lead;
    if (lead == null) return;

    // TL view → "Meet now / View logged meetings". No log path.
    if (_isTlView) {
      final loggedMeetings =
          await _activityRepo.getActivitiesForLead(lead.id);
      final mtgCount = loggedMeetings
          .where((a) => a.type == ActivityType.meeting)
          .length;
      if (!mounted) return;
      final choice = await TlMeetingChooserSheet.show(
        context,
        leadName: lead.fullName,
        loggedMeetingCount: mtgCount,
      );
      if (!mounted || choice == null) return;
      switch (choice) {
        case TlMeetingChoice.meetNow:
          showCompassSnack(context,
              message:
                  'Opening meeting (production: video link / calendar invite)',
              type: CompassSnackType.success);
          break;
        case TlMeetingChoice.viewLogs:
          await MeetingLogsViewerSheet.show(
            context,
            leadName: lead.fullName,
            activities: loggedMeetings,
          );
          break;
      }
      return;
    }

    // Default RM flow.
    final choice = await MeetingActionChooserSheet.show(
      context,
      leadName: lead.fullName,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case MeetingChoice.scheduleNew:
        await _openMeetingCreate();
        break;
      case MeetingChoice.logPast:
        await _onLogPastMeeting();
        break;
    }
  }

  /// Note tile handler. RM logs a note (creates activity entry).
  /// TL view → opens read-only sheet with the RM's notes (no add path,
  /// since notes ARE log entries and TL can't log on the RM's behalf).
  Future<void> _onNoteTap() async {
    final lead = _lead;
    if (lead == null) return;
    if (_isTlView) {
      final activities = await _activityRepo.getActivitiesForLead(lead.id);
      if (!mounted) return;
      await NoteLogsViewerSheet.show(
        context,
        leadName: lead.fullName,
        activities: activities,
      );
      return;
    }
    await _logActivity(ActivityType.note);
  }

  /// "Log a past meeting" path. Shows the scheduled-meetings picker so
  /// the RM can pick which meeting they're logging against. Three
  /// outcomes:
  ///   - Pick a scheduled meeting → log against it (state transition,
  ///     no duplicate record).
  ///   - Cancel a scheduled meeting → mark it cancelled, no log entry.
  ///   - "It wasn't a scheduled meeting" → fall back to creating a fresh
  ///     log entry (walk-in / ad-hoc).
  Future<void> _onLogPastMeeting() async {
    final lead = _lead;
    if (lead == null) return;
    final activities = await _activityRepo.getActivitiesForLead(lead.id);
    final scheduled = selectScheduledMeetings(activities);
    if (!mounted) return;

    final result = await MeetingPickerSheet.show(
      context,
      leadName: lead.fullName,
      scheduledMeetings: scheduled,
    );
    if (!mounted || result == null) return;

    if (result is MeetingPickAdHoc) {
      // Walk-in / ad-hoc — create a fresh entry like the original flow.
      await _logActivity(ActivityType.meeting);
      return;
    }

    if (result is MeetingPickCancel) {
      final title = (result.meeting.notes ?? 'Meeting')
          .split('\n')
          .first
          .trim();
      final confirmed = await showCancelMeetingConfirm(
        context,
        meetingTitle: title.isEmpty ? 'Meeting' : title,
      );
      if (!confirmed || !mounted) return;
      await _activityRepo.updateActivity(
        activityId: result.meeting.id,
        leadId: lead.id,
        outcome: ActivityOutcome.cancelled,
      );
      if (mounted) {
        showCompassSnack(context,
            message: 'Meeting cancelled', type: CompassSnackType.warn);
        await _load();
      }
      return;
    }

    if (result is MeetingPickLog) {
      await _logAgainstScheduledMeeting(result.meeting);
      return;
    }
  }

  /// Logs against an existing scheduled meeting. Opens the standard log
  /// sheet with the meeting's title in the header, captures outcome /
  /// notes / duration, and updates the existing activity record (no
  /// duplicate). Persists next-action and chains a follow-up meeting if
  /// the RM picked Meeting as next-action.
  Future<void> _logAgainstScheduledMeeting(ActivityModel scheduled) async {
    final lead = _lead;
    final user = context.read<AuthCubit>().state.currentUser;
    if (lead == null || user == null) return;

    await ActivityQuickLogSheet.show(
      context,
      leadId: lead.id,
      // Header line tells the RM exactly which meeting they're logging.
      leadName: formatMeetingContext(scheduled),
      preselectedType: ActivityType.meeting,
      onSave: (type, notes, outcome, duration, nextActionType, nextActionDate) async {
        // Combine the original meeting's notes (title / mode / link)
        // with the held-meeting notes the RM just typed, separated by
        // a divider so both are readable in the timeline.
        final combinedNotes = StringBuffer();
        if ((scheduled.notes ?? '').isNotEmpty) {
          combinedNotes.write(scheduled.notes);
          combinedNotes.write('\n— Logged: ');
        }
        combinedNotes.write(notes ?? '');

        await _activityRepo.updateActivity(
          activityId: scheduled.id,
          leadId: lead.id,
          // Keep the originally scheduled date — that's the meeting's
          // historical anchor. The held-meeting log doesn't move it.
          durationMinutes: duration,
          notes: combinedNotes.toString().trim(),
          outcome: outcome ?? ActivityOutcome.completed,
        );
        await _persistNextAction(nextActionType, nextActionDate);

        if (mounted) {
          showCompassSnack(context,
              message: 'Meeting logged',
              type: CompassSnackType.success);
        }
        await _load();
        if (mounted &&
            nextActionType == NextActionType.meeting &&
            nextActionDate != null) {
          await _chainFollowUpMeeting(nextActionDate, user);
        }
      },
    );
  }

  /// Opens the meeting create form. On save, logs the meeting as an
  /// activity (future date → followUp outcome / scheduled, past date →
  /// completed / logged), persists the next action, and chains another
  /// follow-up meeting when next-action is Meeting.
  Future<void> _openMeetingCreate() async {
    final lead = _lead;
    final user = context.read<AuthCubit>().state.currentUser;
    if (lead == null || user == null) return;

    final result = await MeetingCreateSheet.show(
      context,
      leadName: lead.fullName,
    );
    if (!mounted || result == null) return;

    final isFuture = result.when.isAfter(DateTime.now());
    final outcome =
        isFuture ? ActivityOutcome.followUp : ActivityOutcome.completed;

    await _activityRepo.logActivity(
      leadId: lead.id,
      type: ActivityType.meeting,
      dateTime: result.when,
      durationMinutes: result.durationMinutes,
      notes: result.toLogNotes(),
      outcome: outcome,
      loggedById: user.id,
      loggedByName: user.name,
    );

    await _persistNextAction(result.nextActionType, result.nextActionDate);

    if (mounted) {
      showCompassSnack(
        context,
        message: isFuture ? 'Meeting scheduled' : 'Meeting logged',
        type: CompassSnackType.success,
      );
      await _load();
    }
    if (mounted &&
        result.nextActionType == NextActionType.meeting &&
        result.nextActionDate != null) {
      await _chainFollowUpMeeting(result.nextActionDate!, user);
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

  void _onMenuSelected(String value) async {
    final lead = _lead;
    if (lead == null) return;
    switch (value) {
      case 'ib':
        // RM-7: Duplicate IB block — check before opening convert sheet
        final ibRepo = getIt<IbLeadRepository>();
        final allIb = await ibRepo.getAllForBranchHead('');
        final blocking = DuplicateIbCheck.findActiveIbLead(lead.fullName, allIb);
        if (blocking != null) {
          if (mounted) {
            showCompassSnack(
              context,
              message:
                  'This client already has an active IB lead (#$blocking). '
                  'Only one active IB lead per client is allowed.',
              type: CompassSnackType.warn,
            );
          }
          return;
        }
        final confirmed = await showConvertToIbSheet(context, lead);
        if (confirmed == true && mounted) {
          await context.push('/ib-leads/new', extra: {
            'clientName': lead.fullName,
            'companyName': lead.companyName,
            'parentLeadId': lead.id,
            'phone': lead.phone,
            'email': lead.email,
            'city': lead.city,
            'estimatedAum': lead.estimatedAum,
            'notes': lead.notes,
          });
          if (mounted) {
            showCompassSnack(
              context,
              message: 'IB lead created — wealth lead stays in your pipeline',
              type: CompassSnackType.success,
            );
            await _load();
          }
        }
        break;
      case 'edit':
        _editLead();
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
// TL read-only banner — visible at the top of the body when the viewer
// is a Team Lead looking at a reportee's lead.
// ────────────────────────────────────────────────────────────────────

class _TlReadOnlyBanner extends StatelessWidget {
  final String rmName;
  const _TlReadOnlyBanner({required this.rmName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.warmAmber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 16, color: AppColors.warmAmber),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF8A4F00),
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Read-only · Lead owned by '),
                  TextSpan(
                    text: rmName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

// ────────────────────────────────────────────────────────────────────
// Hero header — full identity in the navy block
// ────────────────────────────────────────────────────────────────────

class _LeadHeroHeader extends StatelessWidget {
  final LeadModel lead;
  final ValueChanged<String> onMenu;
  /// In TL-view (reportee's lead), the popup menu (Edit / Convert-to-IB)
  /// is hidden — TL has no state-change rights here.
  final bool isTlView;

  const _LeadHeroHeader({
    required this.lead,
    required this.onMenu,
    this.isTlView = false,
  });

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
              // Popup menu hidden for TL view — Edit / Convert-to-IB are
              // owner-only actions. (Request Reassignment will be added
              // here in the next iteration.)
              if (!isTlView)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white, size: 22),
                  onSelected: onMenu,
                  position: PopupMenuPosition.under,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined, size: 20),
                        title: Text('Edit details'),
                      ),
                    ),
                    // Hide Convert-to-IB when this lead is already linked.
                    if (lead.ibLeadIds.isEmpty)
                      const PopupMenuItem(
                        value: 'ib',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.swap_horiz, size: 20),
                          title: Text('Convert to IB Lead'),
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
                        lead.companyName ??
                            PiiDisplay.phoneFor(
                                lead.phone ?? '', lead.consentStatus),
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
                          if (lead.ibLeadIds.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'IB',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
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
  /// Nullable so the WhatsApp tile can be greyed out for leads with no
  /// phone on file (wealth Add Lead allows phone-less entries).
  final VoidCallback? onWhatsApp;
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

  Widget _tile(IconData icon, String label, Color color, VoidCallback? onTap) {
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
  bool _open = true;

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
                        if (l.phone != null && l.phone!.isNotEmpty)
                          _row('Phone',
                              PiiDisplay.phoneFor(l.phone!, l.consentStatus)),
                        if (l.email != null)
                          _row('Email',
                              PiiDisplay.emailFor(l.email!, l.consentStatus)),
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
  final VoidCallback onDrop;
  final VoidCallback onOnboard;

  const _BottomActionBar({
    required this.onDrop,
    required this.onOnboard,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          border: Border(
            top:
                BorderSide(color: AppColors.borderDefault.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        // Two equal-weight CTAs: Drop (danger) + Onboard (primary).
        // No more "advance stage" — Lead Status was retired across the app.
        child: Row(
          children: [
            Expanded(
              child: CompassButton.danger(
                label: 'Drop',
                icon: Icons.remove_circle_outline,
                onPressed: onDrop,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CompassButton(
                label: 'Onboard Lead',
                icon: Icons.handshake_outlined,
                onPressed: onOnboard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Prominent IB convert CTA
// ────────────────────────────────────────────────────────────────────

class _IbConvertCard extends StatelessWidget {
  final VoidCallback onTap;
  const _IbConvertCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfacePrimary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.navyPrimary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.business_center_outlined, color: AppColors.navyPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert to IB lead',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Create an Investment Banking opportunity',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.navyPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IbConvertedInfo extends StatelessWidget {
  final String ibLeadId;
  const _IbConvertedInfo({required this.ibLeadId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Converted to IB lead · $ibLeadId',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
