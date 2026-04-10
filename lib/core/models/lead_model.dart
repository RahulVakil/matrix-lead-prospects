import '../enums/lead_stage.dart';
import '../enums/lead_temperature.dart';
import '../enums/lead_source.dart';
import '../enums/update_type.dart';
import 'activity_model.dart';
import 'deal_info_model.dart';
import 'next_action_model.dart';
import 'profiling_model.dart';

class LeadModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? companyName;
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

  LeadModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.companyName,
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
  });

  LeadTemperature get temperature =>
      LeadTemperature.fromScore(score, isDormant: stage == LeadStage.dormant);

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
    String? fullName,
    String? phone,
    String? email,
    String? companyName,
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
  }) {
    return LeadModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
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
    );
  }
}
