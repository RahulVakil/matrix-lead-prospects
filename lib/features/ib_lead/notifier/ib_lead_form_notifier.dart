import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/ib_deal_type.dart';
import '../../../core/models/ib_lead_model.dart';
import '../../../core/models/key_contact_model.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/repositories/coverage_repository.dart';
import '../../../core/repositories/ib_lead_repository.dart';
import '../../../core/services/notification_service.dart';
import 'ib_lead_form_state.dart';

class IbLeadFormNotifier extends StateNotifier<IbLeadFormState> {
  final IbLeadRepository _repository;
  final NotificationService _notifications;
  final CoverageRepository _coverage;
  final String createdById;
  final String createdByName;

  IbLeadFormNotifier({
    required IbLeadRepository repository,
    required NotificationService notifications,
    required CoverageRepository coverage,
    required this.createdById,
    required this.createdByName,
    String? initialClientName,
    String? initialClientCode,
    String? initialCompanyName,
  })  : _repository = repository,
        _notifications = notifications,
        _coverage = coverage,
        super(IbLeadFormState(
          clientName: initialClientName,
          clientCode: initialClientCode,
          companyName: initialCompanyName ?? '',
        ));

  /// Optional, non-blocking coverage check.
  /// Result is shown inline in the IB form. RM can submit regardless.
  Future<void> runCoverageCheck() async {
    final company = state.companyName.trim();
    final name = state.clientName?.trim();
    if (company.isEmpty && (name == null || name.isEmpty)) return;
    state = state.copyWith(isCheckingCoverage: true);
    final result = await _coverage.checkCoverage(
      name: name?.isEmpty ?? true ? null : name,
      company: company.isEmpty ? null : company,
    );
    state = state.copyWith(
      isCheckingCoverage: false,
      lastCoverageResult: result,
    );
  }

  void clearCoverage() => state = state.copyWith(clearCoverage: true);

  void setClientName(String v) =>
      state = state.copyWith(clientName: v, clearCoverage: true);
  void setCompanyName(String v) =>
      state = state.copyWith(companyName: v, clearCoverage: true);
  void setContacts(List<KeyContactModel> v) => state = state.copyWith(contacts: v);

  void setDealType(IbDealType? v) => state = state.copyWith(dealType: v);
  void setDealTypeOtherText(String v) => state = state.copyWith(dealTypeOtherText: v);

  void setDealValue(double? v) {
    state = state.copyWith(
      dealValue: v,
      clearDealValue: v == null,
      dealValueRange: v != null ? IbDealValueRange.fromValue(v) : null,
      clearDealValueRange: v == null,
    );
  }

  void setDealValueRange(IbDealValueRange? r) {
    state = state.copyWith(
      dealValueRange: r,
      clearDealValueRange: r == null,
      clearDealValue: true,
    );
  }

  void setDealStage(IbDealStage? v) => state = state.copyWith(dealStage: v);

  void setTimeline(int month, int year) =>
      state = state.copyWith(timelineMonth: month, timelineYear: year);

  void toggleIdentifiedHow(IbIdentifiedHow h) {
    final next = [...state.identifiedHow];
    if (next.contains(h)) {
      next.remove(h);
    } else {
      next.add(h);
    }
    state = state.copyWith(identifiedHow: next);
  }

  void setNotes(String v) => state = state.copyWith(notes: v);
  void setConfidential(bool v) => state = state.copyWith(isConfidential: v);
  void setDeclaration(bool v) => state = state.copyWith(declarationAccepted: v);

  Future<IbLeadModel?> saveDraft() async {
    if (state.companyName.trim().isEmpty || state.dealType == null) {
      state = state.copyWith(submitError: 'Company name and deal type required to save draft.');
      return null;
    }
    return _persist(submit: false);
  }

  Future<IbLeadModel?> submit() async {
    if (!state.isReadyToSubmit) {
      state = state.copyWith(submitError: 'Please complete all required fields.');
      return null;
    }
    return _persist(submit: true);
  }

  Future<IbLeadModel?> _persist({required bool submit}) async {
    state = state.copyWith(isSubmitting: true, submitError: null);
    try {
      final draft = IbLeadModel(
        id: '',
        clientName: state.clientName,
        clientCode: state.clientCode,
        companyName: state.companyName.trim(),
        contacts: state.contacts.where((c) => !c.isEmpty).toList(),
        dealType: state.dealType!,
        dealTypeOtherText: state.dealType == IbDealType.other
            ? state.dealTypeOtherText.trim()
            : null,
        dealValue: state.dealValue,
        dealValueRange: state.dealValueRange ?? IbDealValueRange.upTo10Cr,
        dealStage: state.dealStage!,
        timelineMonth: state.timelineMonth,
        timelineYear: state.timelineYear,
        identifiedHow: state.identifiedHow,
        notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
        isConfidential: state.isConfidential,
        declarationAccepted: state.declarationAccepted,
        status: submit ? IbLeadStatus.pending : IbLeadStatus.draft,
        createdById: createdById,
        createdByName: createdByName,
        createdAt: DateTime.now(),
        submittedAt: submit ? DateTime.now() : null,
      );

      final saved = submit
          ? await _repository.submit(draft)
          : await _repository.saveDraft(draft);

      if (submit) {
        await _notifications.push(
          topic: 'branch-head',
          notification: NotificationModel(
            id: 'NTF_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.ibLeadSubmitted,
            title: 'New IB lead pending',
            body: '$createdByName submitted ${saved.companyName} (${saved.dealType.label})',
            deepLink: '/ib-leads/${saved.id}',
            createdAt: DateTime.now(),
          ),
        );
      }

      state = state.copyWith(isSubmitting: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return null;
    }
  }
}
