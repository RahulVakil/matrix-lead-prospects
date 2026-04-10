import '../models/client_model.dart';
import '../models/paginated_result.dart';

abstract class ClientRepository {
  Future<PaginatedResult<ClientModel>> getClients({
    int page = 1,
    int pageSize = 20,
    String? assignedRmId,
    String? searchQuery,
    bool? directOnly,
  });

  Future<ClientModel?> getClientById(String id);
}
