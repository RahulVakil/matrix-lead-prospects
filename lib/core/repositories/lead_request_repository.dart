import '../models/lead_request.dart';

/// Persistence + state transitions for the Get Lead request workflow.
abstract class LeadRequestRepository {
  /// Persist a new request. Caller is responsible for firing notifications.
  Future<LeadRequest> create(LeadRequest request);

  /// Requests created by a single RM, newest first. Powers the audit
  /// trail on the Get Lead screen for RM viewers.
  Future<List<LeadRequest>> getForRm(String rmId);

  /// Requests for an entire team, newest first. The mock impl derives the
  /// team membership via `MockDataGenerators.findUserById` against each
  /// request's `rmId`. Powers the audit trail for TL viewers.
  Future<List<LeadRequest>> getForTeam(String teamId);

  /// All pending requests, newest first. Powers the Manage Pool Requests
  /// tab.
  Future<List<LeadRequest>> getAllPending();

  /// All requests regardless of status. Available for admin reporting.
  Future<List<LeadRequest>> getAll();

  /// Mark a request fulfilled with the assigned lead IDs. Returns the
  /// updated record. Caller fires the "leads assigned" notifications.
  Future<LeadRequest> markFulfilled(
    String id, {
    required String adminId,
    required String adminName,
    required List<String> assignedLeadIds,
  });
}
