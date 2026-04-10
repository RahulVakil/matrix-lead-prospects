import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_temperature.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';

class LeadInboxState extends Equatable {
  final bool isLoading;
  final List<LeadModel> leads;
  final int totalCount;
  final LeadTemperature? temperatureFilter;
  final String? sortBy;
  final String? searchQuery;
  final int page;
  final String? error;
  final Map<LeadTemperature, int> temperatureCounts;

  const LeadInboxState({
    this.isLoading = true,
    this.leads = const [],
    this.totalCount = 0,
    this.temperatureFilter,
    this.sortBy = 'score',
    this.searchQuery,
    this.page = 1,
    this.error,
    this.temperatureCounts = const {},
  });

  LeadInboxState copyWith({
    bool? isLoading,
    List<LeadModel>? leads,
    int? totalCount,
    LeadTemperature? temperatureFilter,
    bool clearTemperatureFilter = false,
    String? sortBy,
    String? searchQuery,
    bool clearSearchQuery = false,
    int? page,
    String? error,
    Map<LeadTemperature, int>? temperatureCounts,
  }) {
    return LeadInboxState(
      isLoading: isLoading ?? this.isLoading,
      leads: leads ?? this.leads,
      totalCount: totalCount ?? this.totalCount,
      temperatureFilter: clearTemperatureFilter ? null : (temperatureFilter ?? this.temperatureFilter),
      sortBy: sortBy ?? this.sortBy,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      page: page ?? this.page,
      error: error,
      temperatureCounts: temperatureCounts ?? this.temperatureCounts,
    );
  }

  @override
  List<Object?> get props => [isLoading, leads.length, totalCount, temperatureFilter, sortBy, searchQuery, page, error];
}

class LeadInboxCubit extends Cubit<LeadInboxState> {
  final String rmId;

  LeadInboxCubit({required this.rmId}) : super(const LeadInboxState());

  Future<void> loadLeads({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(isLoading: true, page: 1));
    }

    try {
      final repo = getIt<LeadRepository>();
      final result = await repo.getLeads(
        page: state.page,
        temperature: state.temperatureFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        assignedRmId: rmId,
      );

      // Calculate temperature counts from all leads (no filter)
      final allResult = await repo.getLeads(
        page: 1,
        pageSize: 500,
        assignedRmId: rmId,
      );
      final counts = <LeadTemperature, int>{};
      for (final lead in allResult.items) {
        counts[lead.temperature] = (counts[lead.temperature] ?? 0) + 1;
      }

      emit(state.copyWith(
        isLoading: false,
        leads: result.items,
        totalCount: result.totalCount,
        temperatureCounts: counts,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setTemperatureFilter(LeadTemperature? temperature) {
    if (temperature == state.temperatureFilter) {
      emit(state.copyWith(clearTemperatureFilter: true, page: 1));
    } else {
      emit(state.copyWith(temperatureFilter: temperature, page: 1));
    }
    loadLeads(refresh: true);
  }

  void setSort(String sortBy) {
    emit(state.copyWith(sortBy: sortBy, page: 1));
    loadLeads(refresh: true);
  }

  void search(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(clearSearchQuery: true, page: 1));
    } else {
      emit(state.copyWith(searchQuery: query, page: 1));
    }
    loadLeads(refresh: true);
  }
}
