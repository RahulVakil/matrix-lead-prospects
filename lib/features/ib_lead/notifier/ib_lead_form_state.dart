import 'package:equatable/equatable.dart';
import '../../../core/enums/ib_deal_type.dart';
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
  final int? timelineMonth;
  final int? timelineYear;
  final List<IbIdentifiedHow> identifiedHow;
  final String notes;
  final bool isConfidential;
  final bool declarationAccepted;

  final bool isSubmitting;
  final String? submitError;

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
    this.timelineMonth,
    this.timelineYear,
    this.identifiedHow = const [],
    this.notes = '',
    this.isConfidential = false,
    this.declarationAccepted = false,
    this.isSubmitting = false,
    this.submitError,
  });

  bool get isReadyToSubmit {
    return companyName.trim().isNotEmpty &&
        dealType != null &&
        (dealType != IbDealType.other || dealTypeOtherText.trim().isNotEmpty) &&
        dealStage != null &&
        (dealValue != null || dealValueRange != null) &&
        timelineMonth != null &&
        timelineYear != null &&
        identifiedHow.isNotEmpty &&
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
    int? timelineMonth,
    int? timelineYear,
    List<IbIdentifiedHow>? identifiedHow,
    String? notes,
    bool? isConfidential,
    bool? declarationAccepted,
    bool? isSubmitting,
    String? submitError,
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
      dealStage: dealStage ?? this.dealStage,
      timelineMonth: timelineMonth ?? this.timelineMonth,
      timelineYear: timelineYear ?? this.timelineYear,
      identifiedHow: identifiedHow ?? this.identifiedHow,
      notes: notes ?? this.notes,
      isConfidential: isConfidential ?? this.isConfidential,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
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
        timelineMonth,
        timelineYear,
        identifiedHow,
        notes,
        isConfidential,
        declarationAccepted,
        isSubmitting,
        submitError,
      ];
}
