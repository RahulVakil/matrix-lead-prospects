import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/client_model.dart';
import '../../../../core/repositories/client_repository.dart';

enum ClientsFilter { all, direct, reportee }

class ClientsState extends Equatable {
  final bool isLoading;
  final List<ClientModel> clients;
  final ClientsFilter filter;
  final String searchQuery;
  final String? error;

  const ClientsState({
    this.isLoading = true,
    this.clients = const [],
    this.filter = ClientsFilter.all,
    this.searchQuery = '',
    this.error,
  });

  ClientsState copyWith({
    bool? isLoading,
    List<ClientModel>? clients,
    ClientsFilter? filter,
    String? searchQuery,
    String? error,
  }) =>
      ClientsState(
        isLoading: isLoading ?? this.isLoading,
        clients: clients ?? this.clients,
        filter: filter ?? this.filter,
        searchQuery: searchQuery ?? this.searchQuery,
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, clients.length, filter, searchQuery, error];
}

class ClientsCubit extends Cubit<ClientsState> {
  final String? rmId;
  final ClientRepository _repo = getIt<ClientRepository>();

  ClientsCubit({this.rmId}) : super(const ClientsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      final res = await _repo.getClients(
        page: 1,
        pageSize: 50,
        assignedRmId: rmId,
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
        directOnly: state.filter == ClientsFilter.direct ? true : null,
      );
      emit(state.copyWith(isLoading: false, clients: res.items));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setFilter(ClientsFilter f) {
    emit(state.copyWith(filter: f));
    load();
  }

  void search(String q) {
    emit(state.copyWith(searchQuery: q));
    load();
  }
}
