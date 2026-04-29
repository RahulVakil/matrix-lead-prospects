import '../models/reassignment_request.dart';

/// Persistence + state transitions for the lead-coverage reassignment
/// workflow (Manage Pool → REASSIGNMENT tab).
abstract class ReassignmentRepository {
  /// Create a new pending request. Called from `_runCoverage()` in the
  /// wealth Add Lead flow when the RM picks `CoverageDecision.requestReassignment`.
  Future<ReassignmentRequest> create(ReassignmentRequest request);

  /// All pending requests, newest first. Powers the REASSIGNMENT tab list.
  Future<List<ReassignmentRequest>> getAllPending();

  /// All requests (any status), newest first. Available for an Admin
  /// "history" view in a future iteration.
  Future<List<ReassignmentRequest>> getAll();

  /// Approve a pending request. Returns the updated record.
  /// Notifications to source + target RMs are fired by the caller (the
  /// Manage Pool screen) so the queue can use the screen's auth context.
  Future<ReassignmentRequest> approve(
    String id, {
    required String adminId,
    required String adminName,
  });

  /// Reject with a mandatory reason.
  Future<ReassignmentRequest> reject(
    String id, {
    required String reason,
    required String adminId,
    required String adminName,
  });
}
