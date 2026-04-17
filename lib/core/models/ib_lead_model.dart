import '../enums/ib_deal_type.dart';
import 'ib_progress_update.dart';
import 'ib_remark_entry.dart';
import 'key_contact_model.dart';

class IbLeadModel {
  final String id;
  final String? clientName;
  final String? clientCode;
  final String companyName;
  final List<KeyContactModel> contacts;
  // ── Company / lead detail extensions ──────────────────────────────
  final IbIndustry? industry;
  final String? industryOther; // when industry == IbIndustry.other
  final String? websiteUrl;
  final List<IbFinancialDoc> financialDocs;
  // ──────────────────────────────────────────────────────────────────
  final IbDealType dealType;
  final String? dealTypeOtherText;
  final double? dealValue;
  final IbDealValueRange dealValueRange;
  final IbDealStage? dealStage;
  final int? timelineMonths; // 0, 2, 4, 6, 8, 10, 12 (12 means "12+")
  final List<IbIdentifiedHow> identifiedHow;
  final String? notes;
  final bool isConfidential;
  final String? confidentialReason;
  final bool declarationAccepted;
  final IbLeadStatus status;
  final String createdById;
  final String createdByName;
  // Reviewer is now the Admin / MIS user. Field names retained from the
  // original Branch-Head model to avoid a wide rename; UI labels say Admin/MIS.
  final String? branchHeadId;
  final String? branchHeadName;
  final String? remarks;
  // ── Assignment to an IB RM (post-approval) ────────────────────────
  final String? assignedIbRmId;
  final String? assignedIbRmName;
  final DateTime? assignedAt;
  /// CC list captured at the time of assignment (e.g. for the auto email).
  /// Mock-only: stored on the model so it surfaces on the detail screen.
  final List<String> assignmentCcList;
  // ── Sent-back / resubmit conversation thread ──────────────────────
  final List<IbRemarkEntry> remarkThread;
  // ── 30-day cycle ──────────────────────────────────────────────────
  final List<IbProgressUpdate> progressUpdates;
  // ──────────────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;

  const IbLeadModel({
    required this.id,
    this.clientName,
    this.clientCode,
    required this.companyName,
    this.contacts = const [],
    this.industry,
    this.industryOther,
    this.websiteUrl,
    this.financialDocs = const [],
    required this.dealType,
    this.dealTypeOtherText,
    this.dealValue,
    required this.dealValueRange,
    this.dealStage,
    this.timelineMonths,
    this.identifiedHow = const [],
    this.notes,
    this.isConfidential = false,
    this.confidentialReason,
    this.declarationAccepted = false,
    required this.status,
    required this.createdById,
    required this.createdByName,
    this.branchHeadId,
    this.branchHeadName,
    this.remarks,
    this.assignedIbRmId,
    this.assignedIbRmName,
    this.assignedAt,
    this.assignmentCcList = const [],
    this.remarkThread = const [],
    this.progressUpdates = const [],
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

  String get industryDisplay {
    if (industry == null) return '—';
    if (industry == IbIndustry.other && (industryOther ?? '').isNotEmpty) {
      return 'Other: $industryOther';
    }
    return industry!.label;
  }

  /// Derived Hot / Warm / Cold tag from deal stage + timeline.
  /// Hot: mandate-imminent + timeline <= 6 months
  /// Warm: activeDiscussion OR timeline <= 12 months
  /// Cold: everything else
  IbLeadTemperature get temperature {
    final months = timelineMonths;
    final shortTimeline = months != null && months <= 6;
    final mediumTimeline = months != null && months <= 12;
    if ((dealStage == IbDealStage.mandateExpectedSoon ||
            dealStage == IbDealStage.mandateReceived) &&
        shortTimeline) {
      return IbLeadTemperature.hot;
    }
    if (dealStage == IbDealStage.activeDiscussion || mediumTimeline) {
      return IbLeadTemperature.warm;
    }
    return IbLeadTemperature.cold;
  }

  /// Reference timestamp for the weekly reminder clock:
  /// MAX(createdAt, lastStatusUpdateAt) — whichever is later resets the clock.
  DateTime get _lastProgressRef {
    if (progressUpdates.isNotEmpty) return progressUpdates.last.createdAt;
    if (assignedAt != null) return assignedAt!;
    return createdAt;
  }

  int get daysSinceLastProgress =>
      DateTime.now().difference(_lastProgressRef).inDays;

  /// True when the lead is approved + the RM owes a weekly status update (>7 days).
  bool get isProgressOverdue {
    if (!status.isApproved) return false;
    return daysSinceLastProgress > 7;
  }

  /// True when the escalation threshold is breached (>9 days = 7+2).
  /// At this point TL + IB SPOC should be notified.
  bool get isProgressEscalated {
    if (!status.isApproved) return false;
    return daysSinceLastProgress > 9;
  }

  IbProgressStatus? get latestProgressStatus =>
      progressUpdates.isEmpty ? null : progressUpdates.last.status;

  IbLeadModel copyWith({
    String? id,
    String? clientName,
    String? clientCode,
    String? companyName,
    List<KeyContactModel>? contacts,
    IbIndustry? industry,
    String? industryOther,
    String? websiteUrl,
    List<IbFinancialDoc>? financialDocs,
    IbDealType? dealType,
    String? dealTypeOtherText,
    double? dealValue,
    IbDealValueRange? dealValueRange,
    IbDealStage? dealStage,
    int? timelineMonths,
    List<IbIdentifiedHow>? identifiedHow,
    String? notes,
    bool? isConfidential,
    String? confidentialReason,
    bool? declarationAccepted,
    IbLeadStatus? status,
    String? branchHeadId,
    String? branchHeadName,
    String? remarks,
    String? assignedIbRmId,
    String? assignedIbRmName,
    DateTime? assignedAt,
    List<String>? assignmentCcList,
    List<IbRemarkEntry>? remarkThread,
    List<IbProgressUpdate>? progressUpdates,
    DateTime? submittedAt,
    DateTime? decidedAt,
  }) {
    return IbLeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientCode: clientCode ?? this.clientCode,
      companyName: companyName ?? this.companyName,
      contacts: contacts ?? this.contacts,
      industry: industry ?? this.industry,
      industryOther: industryOther ?? this.industryOther,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      financialDocs: financialDocs ?? this.financialDocs,
      dealType: dealType ?? this.dealType,
      dealTypeOtherText: dealTypeOtherText ?? this.dealTypeOtherText,
      dealValue: dealValue ?? this.dealValue,
      dealValueRange: dealValueRange ?? this.dealValueRange,
      dealStage: dealStage ?? this.dealStage,
      timelineMonths: timelineMonths ?? this.timelineMonths,
      identifiedHow: identifiedHow ?? this.identifiedHow,
      notes: notes ?? this.notes,
      isConfidential: isConfidential ?? this.isConfidential,
      confidentialReason: confidentialReason ?? this.confidentialReason,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      status: status ?? this.status,
      createdById: createdById,
      createdByName: createdByName,
      branchHeadId: branchHeadId ?? this.branchHeadId,
      branchHeadName: branchHeadName ?? this.branchHeadName,
      remarks: remarks ?? this.remarks,
      assignedIbRmId: assignedIbRmId ?? this.assignedIbRmId,
      assignedIbRmName: assignedIbRmName ?? this.assignedIbRmName,
      assignedAt: assignedAt ?? this.assignedAt,
      assignmentCcList: assignmentCcList ?? this.assignmentCcList,
      remarkThread: remarkThread ?? this.remarkThread,
      progressUpdates: progressUpdates ?? this.progressUpdates,
      createdAt: createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }
}
