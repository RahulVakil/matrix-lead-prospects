import '../../models/client_master_record.dart';
import '../../models/coverage_check_result.dart';
import '../../models/family_group_model.dart';
import '../../repositories/coverage_repository.dart';
import 'mock_data_generators.dart';

class MockCoverageRepository implements CoverageRepository {
  late final List<ClientMasterRecord> _records;
  late final List<FamilyGroupModel> _families;

  MockCoverageRepository() {
    _records = MockDataGenerators.generateClientMasterRecords();
    _families = MockDataGenerators.generateFamilyGroups(_records);
  }

  /// Look up the family group for a matched record, if one exists.
  FamilyGroupModel? _findFamily(ClientMasterRecord record) {
    final group = record.groupName;
    if (group == null || group.isEmpty) return null;
    try {
      return _families.firstWhere(
        (f) => f.groupName.toLowerCase() == group.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CoverageCheckResult> checkCoverage({
    String? name,
    String? phone,
    String? email,
    String? company,
    String? groupName,
    String? vertical,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Per-spec: only consider Wealth Spectrum client list (clientMaster).
    // Earlier versions also surfaced duplicateLead from leadList — that path
    // is intentionally retired so Add Lead doesn't block on internal lead
    // overlaps; only existing-client conflicts are flagged now.
    final pool = _records
        .where((r) => r.source == CoverageSource.clientMaster)
        .toList();

    // PWG considers Company in addition to Name/Email/Mobile.
    // EWG (and the IB caller, which leaves vertical null) considers
    // Name + Email + Mobile only. ANY single field match is enough to flag.
    final isPwg = (vertical ?? '').toUpperCase() == 'PWG';

    final normPhone = (phone ?? '').replaceAll(RegExp(r'\s+'), '');
    final normEmail = (email ?? '').toLowerCase().trim();
    final normName = (name ?? '').toLowerCase().trim();
    final normCompany = (company ?? '').toLowerCase().trim();

    for (final rec in pool) {
      // Phone
      if (normPhone.isNotEmpty) {
        final rp = rec.phone?.replaceAll(RegExp(r'\s+'), '') ?? '';
        if (rp.isNotEmpty &&
            (rp.endsWith(normPhone) || normPhone.endsWith(rp))) {
          return CoverageCheckResult.existingClient(rec,
              familyMatch: _findFamily(rec));
        }
      }
      // Email
      if (normEmail.isNotEmpty) {
        final re = (rec.email ?? '').toLowerCase().trim();
        if (re.isNotEmpty && re == normEmail) {
          return CoverageCheckResult.existingClient(rec,
              familyMatch: _findFamily(rec));
        }
      }
      // Name (substring is enough — coverage UI shows the matched record)
      if (normName.isNotEmpty &&
          rec.clientName.toLowerCase().contains(normName)) {
        return CoverageCheckResult.existingClient(rec,
            confidence: 0.7, familyMatch: _findFamily(rec));
      }
      // Company — PWG only
      if (isPwg && normCompany.isNotEmpty) {
        final rg = (rec.groupName ?? '').toLowerCase();
        if (rg.isNotEmpty && rg.contains(normCompany)) {
          return CoverageCheckResult.existingClient(rec,
              confidence: 0.7, familyMatch: _findFamily(rec));
        }
      }
    }

    return CoverageCheckResult.clear();
  }

  @override
  Future<List<ClientMasterRecord>> searchByName({
    required String firstName,
    String? lastName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final f = firstName.toLowerCase().trim();
    final l = lastName?.toLowerCase().trim() ?? '';
    return _records.where((r) {
      final name = r.clientName.toLowerCase();
      if (f.isEmpty) return false;
      if (!name.contains(f)) return false;
      if (l.isNotEmpty && !name.contains(l)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<ClientMasterRecord>> searchByGroup(String query) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return _records
        .where((r) => (r.groupName ?? '').toLowerCase().contains(q))
        .toList();
  }

}
