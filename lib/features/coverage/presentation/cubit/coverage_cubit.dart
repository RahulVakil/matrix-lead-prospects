import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/client_master_record.dart';
import '../../../../core/repositories/coverage_repository.dart';

enum CoverageSearchMode { name, group }

class CoverageState extends Equatable {
  final CoverageSearchMode mode;
  final String firstName;
  final String lastName;
  final String groupQuery;
  final bool isSearching;
  final List<ClientMasterRecord> results;
  final bool hasSearched;
  final String? error;

  const CoverageState({
    this.mode = CoverageSearchMode.name,
    this.firstName = '',
    this.lastName = '',
    this.groupQuery = '',
    this.isSearching = false,
    this.results = const [],
    this.hasSearched = false,
    this.error,
  });

  CoverageState copyWith({
    CoverageSearchMode? mode,
    String? firstName,
    String? lastName,
    String? groupQuery,
    bool? isSearching,
    List<ClientMasterRecord>? results,
    bool? hasSearched,
    String? error,
  }) =>
      CoverageState(
        mode: mode ?? this.mode,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        groupQuery: groupQuery ?? this.groupQuery,
        isSearching: isSearching ?? this.isSearching,
        results: results ?? this.results,
        hasSearched: hasSearched ?? this.hasSearched,
        error: error,
      );

  @override
  List<Object?> get props =>
      [mode, firstName, lastName, groupQuery, isSearching, results.length, hasSearched, error];
}

class CoverageCubit extends Cubit<CoverageState> {
  final CoverageRepository _repo = getIt<CoverageRepository>();

  CoverageCubit() : super(const CoverageState());

  void switchMode(CoverageSearchMode mode) {
    emit(state.copyWith(mode: mode, results: const [], hasSearched: false));
  }

  void setFirstName(String v) => emit(state.copyWith(firstName: v));
  void setLastName(String v) => emit(state.copyWith(lastName: v));
  void setGroupQuery(String v) => emit(state.copyWith(groupQuery: v));

  Future<void> search() async {
    emit(state.copyWith(isSearching: true, hasSearched: false));
    try {
      final results = state.mode == CoverageSearchMode.name
          ? await _repo.searchByName(
              firstName: state.firstName,
              lastName: state.lastName.isEmpty ? null : state.lastName,
            )
          : await _repo.searchByGroup(state.groupQuery);
      emit(state.copyWith(
        isSearching: false,
        results: results,
        hasSearched: true,
      ));
    } catch (e) {
      emit(state.copyWith(isSearching: false, error: e.toString(), hasSearched: true));
    }
  }
}
