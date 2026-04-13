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
    String? company,
    String? groupName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Phone match → strongest signal
    if (phone != null && phone.isNotEmpty) {
      final normPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final match = _records.where((r) {
        final rp = r.phone?.replaceAll(RegExp(r'\s+'), '') ?? '';
        return rp.isNotEmpty && (rp.endsWith(normPhone) || normPhone.endsWith(rp));
      }).toList();
      if (match.isNotEmpty) {
        final hit = match.first;
        final family = _findFamily(hit);
        return hit.source == CoverageSource.clientMaster
            ? CoverageCheckResult.existingClient(hit, familyMatch: family)
            : CoverageCheckResult.duplicateLead(hit, familyMatch: family);
      }
    }

    // Name match
    if (name != null && name.isNotEmpty) {
      final q = name.toLowerCase();
      final matches = _records
          .where((r) => r.clientName.toLowerCase().contains(q))
          .toList();
      if (matches.length == 1) {
        final hit = matches.first;
        final family = _findFamily(hit);
        return hit.source == CoverageSource.clientMaster
            ? CoverageCheckResult.existingClient(hit, confidence: 0.7, familyMatch: family)
            : CoverageCheckResult.duplicateLead(hit, confidence: 0.6, familyMatch: family);
      }
      if (matches.length > 1) {
        return CoverageCheckResult.requiresReview(matches.take(5).toList());
      }
    }

    // Group / company match
    if (company != null && company.isNotEmpty) {
      final q = company.toLowerCase();
      final matches = _records
          .where((r) => (r.groupName ?? '').toLowerCase().contains(q))
          .toList();
      if (matches.isNotEmpty) {
        return CoverageCheckResult.requiresReview(matches.take(5).toList());
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

  @override
  Future<List<FamilyGroupModel>> searchByFamily(String groupName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = groupName.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return _families
        .where((f) => f.groupName.toLowerCase().contains(q))
        .toList();
  }
}
