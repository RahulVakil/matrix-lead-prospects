import '../models/client_master_record.dart';
import '../models/coverage_check_result.dart';

/// Repository for the Coverage Check workflow that replaces the SharePoint
/// CRM Search dashboards. Backed by Client Master + Company Master + Lead List
/// data sources internally.
abstract class CoverageRepository {
  /// Real-time coverage check used inline in Create Lead and IB Lead capture.
  Future<CoverageCheckResult> checkCoverage({
    String? name,
    String? phone,
    String? company,
    String? groupName,
  });

  /// Free-form name search (firstName + optional lastName) — mirrors the
  /// published "Name search" view of the SharePoint dashboard.
  Future<List<ClientMasterRecord>> searchByName({
    required String firstName,
    String? lastName,
  });

  /// Free-form group / company search — mirrors the "Group search" view.
  Future<List<ClientMasterRecord>> searchByGroup(String query);
}
