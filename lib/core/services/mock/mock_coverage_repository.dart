import '../../models/client_master_record.dart';
import '../../models/coverage_check_result.dart';
import '../../repositories/coverage_repository.dart';
import 'mock_data_generators.dart';

class MockCoverageRepository implements CoverageRepository {
  late final List<ClientMasterRecord> _records;

  MockCoverageRepository() {
    _records = MockDataGenerators.generateClientMasterRecords();
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
        return hit.source == CoverageSource.clientMaster
            ? CoverageCheckResult.existingClient(hit)
            : CoverageCheckResult.duplicateLead(hit);
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
        return hit.source == CoverageSource.clientMaster
            ? CoverageCheckResult.existingClient(hit, confidence: 0.7)
            : CoverageCheckResult.duplicateLead(hit, confidence: 0.6);
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
}
