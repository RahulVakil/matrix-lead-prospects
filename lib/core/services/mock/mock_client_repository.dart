import '../../models/client_model.dart';
import '../../models/paginated_result.dart';
import '../../repositories/client_repository.dart';
import 'mock_data_generators.dart';

class MockClientRepository implements ClientRepository {
  late final List<ClientModel> _clients;

  MockClientRepository() {
    _clients = MockDataGenerators.generateClients(30);
  }

  @override
  Future<PaginatedResult<ClientModel>> getClients({
    int page = 1,
    int pageSize = 20,
    String? assignedRmId,
    String? searchQuery,
    bool? directOnly,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var list = List<ClientModel>.from(_clients);

    if (assignedRmId != null) {
      list = list.where((c) => c.assignedRmId == assignedRmId).toList();
    }
    if (directOnly == true) {
      list = list.where((c) => c.isDirect).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) {
        return c.fullName.toLowerCase().contains(q) ||
            c.clientCode.toLowerCase().contains(q) ||
            (c.groupName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    list.sort((a, b) => b.aum.compareTo(a.aum));

    final total = list.length;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);
    final items = start < total ? list.sublist(start, end) : <ClientModel>[];

    return PaginatedResult(
      items: items,
      totalCount: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<ClientModel?> getClientById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
