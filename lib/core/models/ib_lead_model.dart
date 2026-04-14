import '../enums/ib_deal_type.dart';
import 'key_contact_model.dart';

class IbLeadModel {
  final String id;
  final String? clientName;
  final String? clientCode;
  final String companyName;
  final List<KeyContactModel> contacts;
  final IbDealType dealType;
  final String? dealTypeOtherText;
  final double? dealValue;
  final IbDealValueRange dealValueRange;
  final IbDealStage? dealStage;
  final int? timelineMonths; // 0, 2, 4, 6, 8, 10, 12 (12 means "12+")
  final List<IbIdentifiedHow> identifiedHow;
  final String? notes;
  final bool isConfidential;
  final bool declarationAccepted;
  final IbLeadStatus status;
  final String createdById;
  final String createdByName;
  final String? branchHeadId;
  final String? branchHeadName;
  final String? remarks;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;

  const IbLeadModel({
    required this.id,
    this.clientName,
    this.clientCode,
    required this.companyName,
    this.contacts = const [],
    required this.dealType,
    this.dealTypeOtherText,
    this.dealValue,
    required this.dealValueRange,
    this.dealStage,
    this.timelineMonths,
    this.identifiedHow = const [],
    this.notes,
    this.isConfidential = false,
    this.declarationAccepted = false,
    required this.status,
    required this.createdById,
    required this.createdByName,
    this.branchHeadId,
    this.branchHeadName,
    this.remarks,
    required this.createdAt,
    this.submittedAt,
    this.decidedAt,
  });

  String get timelineDisplay {
    if (timelineMonths == null) return '—';
    final m = timelineMonths!;
    if (m == 0) return 'Now';
    if (m >= 24) return '1 Year +';
    if (m == 12) return '1 Year';
    if (m > 12) return '1 Year ${m - 12} M';
    return '$m months';
  }

  String get dealTypeDisplay => dealType == IbDealType.other && dealTypeOtherText != null
      ? 'Other: $dealTypeOtherText'
      : dealType.label;

  IbLeadModel copyWith({
    String? id,
    String? clientName,
    String? clientCode,
    String? companyName,
    List<KeyContactModel>? contacts,
    IbDealType? dealType,
    String? dealTypeOtherText,
    double? dealValue,
    IbDealValueRange? dealValueRange,
    IbDealStage? dealStage,
    int? timelineMonths,
    List<IbIdentifiedHow>? identifiedHow,
    String? notes,
    bool? isConfidential,
    bool? declarationAccepted,
    IbLeadStatus? status,
    String? branchHeadId,
    String? branchHeadName,
    String? remarks,
    DateTime? submittedAt,
    DateTime? decidedAt,
  }) {
    return IbLeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientCode: clientCode ?? this.clientCode,
      companyName: companyName ?? this.companyName,
      contacts: contacts ?? this.contacts,
      dealType: dealType ?? this.dealType,
      dealTypeOtherText: dealTypeOtherText ?? this.dealTypeOtherText,
      dealValue: dealValue ?? this.dealValue,
      dealValueRange: dealValueRange ?? this.dealValueRange,
      dealStage: dealStage ?? this.dealStage,
      timelineMonths: timelineMonths ?? this.timelineMonths,
      identifiedHow: identifiedHow ?? this.identifiedHow,
      notes: notes ?? this.notes,
      isConfidential: isConfidential ?? this.isConfidential,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      status: status ?? this.status,
      createdById: createdById,
      createdByName: createdByName,
      branchHeadId: branchHeadId ?? this.branchHeadId,
      branchHeadName: branchHeadName ?? this.branchHeadName,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }
}
