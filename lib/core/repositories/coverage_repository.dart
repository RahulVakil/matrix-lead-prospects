import '../models/client_master_record.dart';
import '../models/coverage_check_result.dart';
import '../models/family_group_model.dart';

/// Repository for the Coverage Check workflow that replaces the SharePoint
/// CRM Search dashboards. Backed by Client Master + Company Master + Lead List
/// data sources internally.
abstract class CoverageRepository {
  /// Real-time coverage check used inline in Create Lead and IB Lead capture.
  /// Wealth-side de-dupe rules vary by vertical:
  ///   EWG: match on Full Name OR Email OR Mobile (against Wealth Spectrum
  ///        client master only).
  ///   PWG: same as EWG plus Company Name.
  /// Pass [vertical] = 'EWG' | 'PWG'. The IB caller leaves it null and gets
  /// the EWG-style behavior, which is unchanged from its prior contract
  /// (name + company match against the same client master records).
  Future<CoverageCheckResult> checkCoverage({
    String? name,
    String? phone,
    String? email,
    String? company,
    String? groupName,
    String? vertical,
  });

  /// Free-form name search (firstName + optional lastName) — mirrors the
  /// published "Name search" view of the SharePoint dashboard.
  Future<List<ClientMasterRecord>> searchByName({
    required String firstName,
    String? lastName,
  });

  /// Free-form group / company search — mirrors the "Group search" view.
  Future<List<ClientMasterRecord>> searchByGroup(String query);

  /// Family-level search — returns the full family group with all members.
  Future<List<FamilyGroupModel>> searchByFamily(String groupName);
}
