import 'package:equatable/equatable.dart';
import '../../../core/enums/ib_deal_type.dart';
import '../../../core/models/coverage_check_result.dart';
import '../../../core/models/key_contact_model.dart';

class IbLeadFormState extends Equatable {
  final String? clientName;
  final String? clientCode;
  final String companyName;
  final List<KeyContactModel> contacts;
  final IbDealType? dealType;
  final String dealTypeOtherText;
  final double? dealValue;
  final IbDealValueRange? dealValueRange;
  final IbDealStage? dealStage;
  final int? timelineMonths;
  final List<IbIdentifiedHow> identifiedHow;
  final String notes;
  final bool isConfidential;
  final bool declarationAccepted;

  final bool isSubmitting;
  final String? submitError;

  /// Coverage check is OPTIONAL in IB and never blocks submit. Result is shown
  /// inline below the company name field as informational only.
  final bool isCheckingCoverage;
  final CoverageCheckResult? lastCoverageResult;

  const IbLeadFormState({
    this.clientName,
    this.clientCode,
    this.companyName = '',
    this.contacts = const [],
    this.dealType,
    this.dealTypeOtherText = '',
    this.dealValue,
    this.dealValueRange,
    this.dealStage,
    this.timelineMonths,
    this.identifiedHow = const [],
    this.notes = '',
    this.isConfidential = false,
    this.declarationAccepted = false,
    this.isSubmitting = false,
    this.submitError,
    this.isCheckingCoverage = false,
    this.lastCoverageResult,
  });

  bool get isReadyToSubmit {
    return companyName.trim().isNotEmpty &&
        dealType != null &&
        (dealType != IbDealType.other || dealTypeOtherText.trim().isNotEmpty) &&
        (dealValue != null || dealValueRange != null) &&
        declarationAccepted;
  }

  IbLeadFormState copyWith({
    String? clientName,
    String? clientCode,
    String? companyName,
    List<KeyContactModel>? contacts,
    IbDealType? dealType,
    String? dealTypeOtherText,
    double? dealValue,
    bool clearDealValue = false,
    IbDealValueRange? dealValueRange,
    bool clearDealValueRange = false,
    IbDealStage? dealStage,
    int? timelineMonths,
    bool clearTimelineMonths = false,
    bool clearDealStage = false,
    List<IbIdentifiedHow>? identifiedHow,
    String? notes,
    bool? isConfidential,
    bool? declarationAccepted,
    bool? isSubmitting,
    String? submitError,
    bool? isCheckingCoverage,
    CoverageCheckResult? lastCoverageResult,
    bool clearCoverage = false,
  }) {
    return IbLeadFormState(
      clientName: clientName ?? this.clientName,
      clientCode: clientCode ?? this.clientCode,
      companyName: companyName ?? this.companyName,
      contacts: contacts ?? this.contacts,
      dealType: dealType ?? this.dealType,
      dealTypeOtherText: dealTypeOtherText ?? this.dealTypeOtherText,
      dealValue: clearDealValue ? null : (dealValue ?? this.dealValue),
      dealValueRange:
          clearDealValueRange ? null : (dealValueRange ?? this.dealValueRange),
      dealStage: clearDealStage ? null : (dealStage ?? this.dealStage),
      timelineMonths:
          clearTimelineMonths ? null : (timelineMonths ?? this.timelineMonths),
      identifiedHow: identifiedHow ?? this.identifiedHow,
      notes: notes ?? this.notes,
      isConfidential: isConfidential ?? this.isConfidential,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      isCheckingCoverage: isCheckingCoverage ?? this.isCheckingCoverage,
      lastCoverageResult:
          clearCoverage ? null : (lastCoverageResult ?? this.lastCoverageResult),
    );
  }

  @override
  List<Object?> get props => [
        clientName,
        clientCode,
        companyName,
        contacts.length,
        dealType,
        dealTypeOtherText,
        dealValue,
        dealValueRange,
        dealStage,
        timelineMonths,
        identifiedHow,
        notes,
        isConfidential,
        declarationAccepted,
        isSubmitting,
        submitError,
        isCheckingCoverage,
        lastCoverageResult?.status,
      ];
}
