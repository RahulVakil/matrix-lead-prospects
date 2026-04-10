import 'client_master_record.dart';

enum CoverageStatus {
  clear,
  existingClient,
  duplicateLead,
  requiresReview,
  dnd,
}

class CoverageCheckResult {
  final CoverageStatus status;
  final String message;
  final ClientMasterRecord? matchedRecord;
  final String? existingClientName;
  final String? existingRmName;
  final String? existingRmId;
  final String? existingLeadId;
  final CoverageSource? source;
  final double? confidence; // 0..1
  final List<ClientMasterRecord> alternateMatches;

  CoverageCheckResult({
    required this.status,
    required this.message,
    this.matchedRecord,
    this.existingClientName,
    this.existingRmName,
    this.existingRmId,
    this.existingLeadId,
    this.source,
    this.confidence,
    this.alternateMatches = const [],
  });

  bool get canProceed => status == CoverageStatus.clear;
  bool get isBlocking => status == CoverageStatus.existingClient;

  factory CoverageCheckResult.clear() => CoverageCheckResult(
        status: CoverageStatus.clear,
        message: 'No coverage found. Safe to capture.',
      );

  factory CoverageCheckResult.existingClient(
    ClientMasterRecord record, {
    double confidence = 0.95,
  }) =>
      CoverageCheckResult(
        status: CoverageStatus.existingClient,
        message:
            '${record.clientName} is already a client managed by ${record.rmName ?? 'another RM'}.',
        matchedRecord: record,
        existingClientName: record.clientName,
        existingRmName: record.rmName,
        existingRmId: record.rmId,
        source: record.source,
        confidence: confidence,
      );

  factory CoverageCheckResult.duplicateLead(
    ClientMasterRecord record, {
    double confidence = 0.85,
  }) =>
      CoverageCheckResult(
        status: CoverageStatus.duplicateLead,
        message:
            'A lead with similar details already exists with ${record.rmName ?? 'another RM'}.',
        matchedRecord: record,
        existingLeadId: record.id,
        existingRmName: record.rmName,
        existingRmId: record.rmId,
        source: record.source,
        confidence: confidence,
      );

  factory CoverageCheckResult.requiresReview(
    List<ClientMasterRecord> matches,
  ) =>
      CoverageCheckResult(
        status: CoverageStatus.requiresReview,
        message:
            'Found ${matches.length} potential matches. Review before proceeding.',
        alternateMatches: matches,
      );
}
