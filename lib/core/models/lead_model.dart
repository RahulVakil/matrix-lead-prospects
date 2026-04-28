import '../enums/consent_type.dart';
import '../enums/lead_entity_type.dart';
import '../enums/lead_stage.dart';
import '../enums/lead_temperature.dart';
import '../enums/lead_source.dart';
import '../enums/retention_status.dart';
import '../enums/update_type.dart';
import 'activity_model.dart';
import 'admin_action_record.dart';
import 'consent_record.dart';
import 'deal_info_model.dart';
import 'key_contact_model.dart';
import 'next_action_model.dart';
import 'profiling_model.dart';

class LeadModel {
  final String id;
  final LeadEntityType entityType;
  /// Free-text qualifier captured when [entityType] is `LeadEntityType.others`.
  final String? entityTypeOther;
  final String fullName; // computed for Individual, direct for Non-Individual
  final String? firstName;
  final String? middleName;
  final String? lastName;
  /// Optional — both phone and email are user-optional on the wealth Add Lead
  /// form. Display sites must handle null with `??`. Action launchers
  /// (Call / WhatsApp / SMS) gate themselves on a non-empty phone.
  final String? phone;
  final String? email;
  final String? companyName;
  /// Key contact people for non-individual leads (Partnership, LLP, etc.).
  /// Empty for individuals.
  final List<KeyContactModel> keyContacts;
  final bool hasRequestedConnect;
  final String? connectRepName;
  final String? connectRepPhone;
  final String? connectRepEmail;
  final String? city;
  final LeadSource source;
  final String? referredBy;
  final LeadStage stage;
  final int score;
  final double? estimatedAum;
  final List<String> productInterest;
  final String assignedRmId;
  final String assignedRmName;
  final String? teamLeadId;
  final String vertical; // EWG or PWG
  final String? bestContactTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastContactedAt;
  final DateTime? nextFollowUp;
  final bool isDraft;
  final LeadStage? previousStage; // for dormant recovery
  final DealInfoModel? dealInfo;
  final ProfilingModel? profiling;
  final List<ActivityModel> recentActivities;
  final NextActionModel? nextAction;
  final LeadUpdateStatus? latestStatus;
  final List<String> ibLeadIds;
  final DateTime? ibConvertedAt;

  // Drop tracking
  final DropReason? dropReason;
  final String? dropNotes;
  final DateTime? droppedAt;
  final String? droppedByUserId;
  final bool returnToPoolApproved; // Admin/MIS can approve return to Get Lead pool
  final List<AdminActionRecord> adminActionRecords;

  // DPDP Act compliance fields
  final ConsentStatus consentStatus;
  final List<ConsentRecord> consentRecords;
  final RetentionStatus retentionStatus;
  final String? groupName; // family/group linkage for coverage

  LeadModel({
    required this.id,
    this.entityType = LeadEntityType.individual,
    this.entityTypeOther,
    required this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.phone,
    this.email,
    this.companyName,
    this.keyContacts = const [],
    this.hasRequestedConnect = false,
    this.connectRepName,
    this.connectRepPhone,
    this.connectRepEmail,
    this.city,
    required this.source,
    this.referredBy,
    required this.stage,
    required this.score,
    this.estimatedAum,
    this.productInterest = const [],
    required this.assignedRmId,
    required this.assignedRmName,
    this.teamLeadId,
    this.vertical = 'EWG',
    this.bestContactTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.lastContactedAt,
    this.nextFollowUp,
    this.isDraft = false,
    this.previousStage,
    this.dealInfo,
    this.profiling,
    this.recentActivities = const [],
    this.nextAction,
    this.latestStatus,
    this.ibLeadIds = const [],
    this.ibConvertedAt,
    this.dropReason,
    this.dropNotes,
    this.droppedAt,
    this.droppedByUserId,
    this.returnToPoolApproved = false,
    this.adminActionRecords = const [],
    this.consentStatus = ConsentStatus.pending,
    this.consentRecords = const [],
    this.retentionStatus = RetentionStatus.active,
    this.groupName,
  });

  /// Wealth lead temperature is purely age-based:
  ///   <30 days from createdAt  → Hot
  ///   30-90 days                → Warm
  ///   >90 days                  → Cold
  /// Dormant stage overrides the age rule.
  LeadTemperature get temperature {
    if (stage == LeadStage.dormant) return LeadTemperature.dormant;
    final ageDays = DateTime.now().difference(createdAt).inDays;
    if (ageDays < 30) return LeadTemperature.hot;
    if (ageDays <= 90) return LeadTemperature.warm;
    return LeadTemperature.cold;
  }

  Duration? get timeSinceLastContact {
    if (lastContactedAt == null) return null;
    return DateTime.now().difference(lastContactedAt!);
  }

  String get lastContactDisplay {
    final dur = timeSinceLastContact;
    if (dur == null) return 'Never';
    if (dur.inHours < 1) return '${dur.inMinutes}m ago';
    if (dur.inHours < 24) return '${dur.inHours}h ago';
    if (dur.inDays < 7) return '${dur.inDays}d ago';
    return '${(dur.inDays / 7).floor()}w ago';
  }

  bool get isOverdue {
    if (lastContactedAt == null && stage == LeadStage.lead) {
      return DateTime.now().difference(createdAt).inHours > 24;
    }
    final dur = timeSinceLastContact;
    if (dur == null) return false;
    return dur.inDays > stage.slaDays;
  }

  bool get needsFollowUpToday {
    if (nextFollowUp == null) return false;
    final now = DateTime.now();
    return nextFollowUp!.year == now.year &&
        nextFollowUp!.month == now.month &&
        nextFollowUp!.day == now.day;
  }

  bool get isNewAssignment {
    return DateTime.now().difference(createdAt).inHours < 24 &&
        stage == LeadStage.lead;
  }

  String get aumDisplay {
    if (estimatedAum == null) return 'Unknown';
    if (estimatedAum! >= 10000000) {
      return '₹${(estimatedAum! / 10000000).toStringAsFixed(1)} Cr';
    }
    if (estimatedAum! >= 100000) {
      return '₹${(estimatedAum! / 100000).toStringAsFixed(1)} L';
    }
    return '₹${estimatedAum!.toStringAsFixed(0)}';
  }

  LeadModel copyWith({
    String? id,
    LeadEntityType? entityType,
    String? entityTypeOther,
    String? fullName,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? email,
    String? companyName,
    List<KeyContactModel>? keyContacts,
    bool? hasRequestedConnect,
    String? connectRepName,
    String? connectRepPhone,
    String? connectRepEmail,
    String? city,
    LeadSource? source,
    String? referredBy,
    LeadStage? stage,
    int? score,
    double? estimatedAum,
    List<String>? productInterest,
    String? assignedRmId,
    String? assignedRmName,
    String? teamLeadId,
    String? vertical,
    String? bestContactTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastContactedAt,
    DateTime? nextFollowUp,
    bool? isDraft,
    LeadStage? previousStage,
    DealInfoModel? dealInfo,
    ProfilingModel? profiling,
    List<ActivityModel>? recentActivities,
    NextActionModel? nextAction,
    bool clearNextAction = false,
    LeadUpdateStatus? latestStatus,
    List<String>? ibLeadIds,
    DateTime? ibConvertedAt,
    DropReason? dropReason,
    String? dropNotes,
    DateTime? droppedAt,
    String? droppedByUserId,
    bool? returnToPoolApproved,
    List<AdminActionRecord>? adminActionRecords,
    ConsentStatus? consentStatus,
    List<ConsentRecord>? consentRecords,
    RetentionStatus? retentionStatus,
    String? groupName,
  }) {
    return LeadModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityTypeOther: entityTypeOther ?? this.entityTypeOther,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      keyContacts: keyContacts ?? this.keyContacts,
      hasRequestedConnect: hasRequestedConnect ?? this.hasRequestedConnect,
      connectRepName: connectRepName ?? this.connectRepName,
      connectRepPhone: connectRepPhone ?? this.connectRepPhone,
      connectRepEmail: connectRepEmail ?? this.connectRepEmail,
      city: city ?? this.city,
      source: source ?? this.source,
      referredBy: referredBy ?? this.referredBy,
      stage: stage ?? this.stage,
      score: score ?? this.score,
      estimatedAum: estimatedAum ?? this.estimatedAum,
      productInterest: productInterest ?? this.productInterest,
      assignedRmId: assignedRmId ?? this.assignedRmId,
      assignedRmName: assignedRmName ?? this.assignedRmName,
      teamLeadId: teamLeadId ?? this.teamLeadId,
      vertical: vertical ?? this.vertical,
      bestContactTime: bestContactTime ?? this.bestContactTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      isDraft: isDraft ?? this.isDraft,
      previousStage: previousStage ?? this.previousStage,
      dealInfo: dealInfo ?? this.dealInfo,
      profiling: profiling ?? this.profiling,
      recentActivities: recentActivities ?? this.recentActivities,
      nextAction: clearNextAction ? null : (nextAction ?? this.nextAction),
      latestStatus: latestStatus ?? this.latestStatus,
      ibLeadIds: ibLeadIds ?? this.ibLeadIds,
      ibConvertedAt: ibConvertedAt ?? this.ibConvertedAt,
      dropReason: dropReason ?? this.dropReason,
      dropNotes: dropNotes ?? this.dropNotes,
      droppedAt: droppedAt ?? this.droppedAt,
      droppedByUserId: droppedByUserId ?? this.droppedByUserId,
      returnToPoolApproved: returnToPoolApproved ?? this.returnToPoolApproved,
      adminActionRecords: adminActionRecords ?? this.adminActionRecords,
      consentStatus: consentStatus ?? this.consentStatus,
      consentRecords: consentRecords ?? this.consentRecords,
      retentionStatus: retentionStatus ?? this.retentionStatus,
      groupName: groupName ?? this.groupName,
    );
  }
}
