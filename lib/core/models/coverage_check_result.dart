import 'client_master_record.dart';
import 'family_group_model.dart';

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

  /// Family-level match — populated when the matched record belongs to a
  /// known family group. Shows all members of the family for full context.
  final FamilyGroupModel? familyMatch;

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
    this.familyMatch,
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
    FamilyGroupModel? familyMatch,
  }) =>
      CoverageCheckResult(
        status: CoverageStatus.existingClient,
        message:
            'This person is already a client of the firm — managed by ${record.rmName ?? 'another RM'}.',
        matchedRecord: record,
        existingClientName: record.clientName,
        existingRmName: record.rmName,
        existingRmId: record.rmId,
        source: record.source,
        confidence: confidence,
        familyMatch: familyMatch,
      );

  factory CoverageCheckResult.duplicateLead(
    ClientMasterRecord record, {
    double confidence = 0.85,
    FamilyGroupModel? familyMatch,
  }) =>
      CoverageCheckResult(
        status: CoverageStatus.duplicateLead,
        message:
            '${record.rmName ?? 'Another RM'} is already working this lead.',
        matchedRecord: record,
        existingLeadId: record.id,
        existingRmName: record.rmName,
        existingRmId: record.rmId,
        source: record.source,
        confidence: confidence,
        familyMatch: familyMatch,
      );

  factory CoverageCheckResult.requiresReview(
    List<ClientMasterRecord> matches,
  ) =>
      CoverageCheckResult(
        status: CoverageStatus.requiresReview,
        message:
            'We found ${matches.length} similar record${matches.length == 1 ? '' : 's'} — could be the same person.',
        alternateMatches: matches,
      );
}
