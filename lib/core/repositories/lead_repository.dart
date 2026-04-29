import '../models/lead_model.dart';
import '../models/coverage_check_result.dart';
import '../models/next_action_model.dart';
import '../models/paginated_result.dart';
import '../models/timeline_entry_model.dart';
import '../enums/lead_stage.dart';
import '../enums/lead_temperature.dart';
import '../enums/lead_source.dart';
import '../enums/loss_reason.dart';
import '../enums/update_type.dart';
import '../../features/get_lead/get_lead_dashboard_data.dart';

abstract class LeadRepository {
  /// Lead listing. Scope filters [assignedRmId] / [assignedTeamId] /
  /// [region] / [zone] are mutually layered: the repo derives team/region/
  /// zone from the assigned RM's user record (mock-friendly). Pass at most
  /// one — the cubit picks the right one based on `DashboardScope`.
  Future<PaginatedResult<LeadModel>> getLeads({
    int page = 1,
    int pageSize = 20,
    LeadStage? stage,
    LeadTemperature? temperature,
    LeadSource? source,
    String? searchQuery,
    String? sortBy,
    bool ascending = false,
    String? assignedRmId,
    String? assignedTeamId,
    String? region,
    String? zone,
  });

  Future<LeadModel> getLeadById(String id);

  Future<LeadModel> createLead(LeadModel lead);

  Future<LeadModel> updateLead(LeadModel lead);

  Future<LeadModel> updateLeadStage(
    String id,
    LeadStage newStage, {
    String? reason,
    String? notes,
  });

  Future<LeadModel> markLost(
    String id,
    LossReason reason, {
    String? notes,
    DateTime? reopenDate,
  });

  Future<LeadModel> parkLead(
    String id,
    ParkReason reason,
    DateTime followUpDate, {
    String? notes,
  });

  Future<CoverageCheckResult> checkCoverage(String phone, {String? pan});

  Future<Map<LeadStage, int>> getPipelineSummary(String rmId);

  /// Set or clear the "next action" attached to a lead. Pass null to clear.
  Future<LeadModel> setNextAction(String leadId, NextActionModel? action);

  /// Append a Quick Update entry on a lead and update its latest status.
  Future<LeadModel> addStatusUpdate(
    String leadId, {
    required LeadUpdateStatus status,
    String? notes,
    required String authorId,
    required String authorName,
  });

  /// Build the merged timeline (activities + status updates + stage changes
  /// + deal edits + IB events) for a lead, sorted newest first.
  Future<List<TimelineEntryModel>> getTimeline(String leadId);

  /// Drop a lead. Notes are mandatory; reason is optional (the RM may not
  /// have a clean enum value for the situation). Only RM can drop.
  Future<LeadModel> dropLead(
    String leadId, {
    DropReason? reason,
    required String notes,
    required String droppedByUserId,
  });

  /// Admin/MIS approves a dropped lead to return to the Get Lead pool.
  Future<LeadModel> returnDroppedToPool(String leadId);

  /// Get all dropped leads (for Admin/MIS review).
  Future<List<LeadModel>> getDroppedLeads();

  /// All leads currently in the shared pool (for Admin Assign tab).
  Future<List<LeadModel>> getPoolLeads();

  // ── Pool / Get Lead workflow ────────────────────────────────────────

  /// Total leads sitting in the shared pool, optionally filtered.
  Future<int> getPoolCount({String? vertical, String? aumBand, String? source});

  /// Pool composition by vertical, source, AUM band.
  Future<Map<String, int>> getPoolBreakdown();

  /// Append a batch of new leads directly to the shared pool. Used by the
  /// Admin Pool Upload tab to ingest single-row entries or bulk-CSV
  /// uploads. Returns the count actually inserted.
  Future<int> addPoolLeads(List<LeadModel> leads);

  /// Returns the next pool lead matching the given filters without claiming
  /// it. [excludeIds] lets the RM "skip" a lead and ask for the next one.
  Future<LeadModel?> peekNextFromPool({
    String? vertical,
    String? aumBand,
    String? source,
    Set<String> excludeIds = const {},
  });

  /// Removes the lead from the pool and assigns it to the requesting RM.
  /// Returns the updated [LeadModel] (now with the RM as owner) which is also
  /// inserted into the main `_leads` list so it appears in pipeline.
  Future<LeadModel> claimFromPool(String leadId, String rmId, String rmName);

  /// Claim [count] leads from the pool in one shot, honoring this RM's
  /// weekly budget. Throws if the request exceeds the effective cap.
  Future<List<LeadModel>> claimBatchFromPool({
    required String rmId,
    required String rmName,
    required int count,
  });

  /// Aggregate metrics for the Get Lead Dashboard (RM + TL).
  Future<GetLeadDashboardData> getLeadDashboard(String rmId);
}
