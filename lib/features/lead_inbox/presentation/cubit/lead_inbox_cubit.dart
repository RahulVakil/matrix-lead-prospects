import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/lead_stage.dart';
import '../../../../core/models/lead_model.dart';
import '../../../../core/repositories/lead_repository.dart';

class LeadInboxState extends Equatable {
  final bool isLoading;
  final List<LeadModel> leads;
  final int totalCount;
  final LeadStage? stageFilter;
  final bool ibLinkedOnly;
  final bool myLeadsOnly;
  final String? sortBy;
  final String? searchQuery;
  final int page;
  final String? error;

  const LeadInboxState({
    this.isLoading = true,
    this.leads = const [],
    this.totalCount = 0,
    this.stageFilter,
    this.ibLinkedOnly = false,
    this.myLeadsOnly = false,
    this.sortBy = 'name',
    this.searchQuery,
    this.page = 1,
    this.error,
  });

  LeadInboxState copyWith({
    bool? isLoading,
    List<LeadModel>? leads,
    int? totalCount,
    LeadStage? stageFilter,
    bool clearStageFilter = false,
    bool? ibLinkedOnly,
    bool? myLeadsOnly,
    String? sortBy,
    String? searchQuery,
    bool clearSearchQuery = false,
    int? page,
    String? error,
  }) {
    return LeadInboxState(
      isLoading: isLoading ?? this.isLoading,
      leads: leads ?? this.leads,
      totalCount: totalCount ?? this.totalCount,
      stageFilter:
          clearStageFilter ? null : (stageFilter ?? this.stageFilter),
      ibLinkedOnly: ibLinkedOnly ?? this.ibLinkedOnly,
      myLeadsOnly: myLeadsOnly ?? this.myLeadsOnly,
      sortBy: sortBy ?? this.sortBy,
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      page: page ?? this.page,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        leads.length,
        totalCount,
        stageFilter,
        ibLinkedOnly,
        myLeadsOnly,
        sortBy,
        searchQuery,
        page,
        error,
      ];
}

class LeadInboxCubit extends Cubit<LeadInboxState> {
  final String rmId;
  Timer? _searchDebounce;

  LeadInboxCubit({required this.rmId}) : super(const LeadInboxState());

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadLeads({bool refresh = false}) async {
    if (refresh) {
      emit(state.copyWith(isLoading: true, page: 1));
    }

    try {
      final repo = getIt<LeadRepository>();
      final result = await repo.getLeads(
        page: state.page,
        stage: state.stageFilter,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        assignedRmId: rmId,
      );

      var items = result.items;
      if (state.ibLinkedOnly) {
        items = items.where((l) => l.ibLeadIds.isNotEmpty).toList();
      }
      if (state.myLeadsOnly) {
        items = items.where((l) => l.assignedRmId == rmId).toList();
      }

      emit(state.copyWith(
        isLoading: false,
        leads: items,
        totalCount: result.totalCount,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setStageFilter(LeadStage? stage) {
    emit(state.copyWith(
      stageFilter: stage,
      clearStageFilter: stage == null,
      page: 1,
    ));
    loadLeads(refresh: true);
  }

  void setIbLinkedOnly(bool v) {
    emit(state.copyWith(ibLinkedOnly: v, page: 1));
    loadLeads(refresh: true);
  }

  void setMyLeadsOnly(bool v) {
    emit(state.copyWith(myLeadsOnly: v, page: 1));
    loadLeads(refresh: true);
  }

  void setSort(String sortBy) {
    emit(state.copyWith(sortBy: sortBy, page: 1));
    loadLeads(refresh: true);
  }

  void search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(clearSearchQuery: true, page: 1));
    } else {
      // Optimistic client-side pre-filter: name, company, group only (#1).
      final q = trimmed.toLowerCase();
      final preview = state.leads.where((l) {
        bool nameHit(String name) {
          final n = name.toLowerCase();
          return n.contains(q) ||
              n.split(RegExp(r'\s+')).any((t) => t.startsWith(q));
        }
        return nameHit(l.fullName) ||
            (l.companyName?.toLowerCase().contains(q) ?? false) ||
            (l.groupName?.toLowerCase().contains(q) ?? false);
      }).toList();
      emit(state.copyWith(
        searchQuery: trimmed,
        leads: preview,
        page: 1,
      ));
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      loadLeads(refresh: true);
    });
  }
}
