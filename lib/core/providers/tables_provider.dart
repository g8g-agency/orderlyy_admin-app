import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/table_dto.dart';
import '../data/repositories/tables_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';
import 'branch_context_service.dart';
import '../network/cancellation_service.dart';
import 'package:dio/dio.dart';

class TablesState {
  final bool isLoading;
  final String? error;

  // Normalized map of tables by ID
  final Map<String, RestaurantTableDto> tablesById;

  const TablesState({
    this.isLoading = false,
    this.error,
    this.tablesById = const {},
  });

  TablesState copyWith({
    bool? isLoading,
    String? error,
    Map<String, RestaurantTableDto>? tablesById,
  }) {
    return TablesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tablesById: tablesById ?? this.tablesById,
    );
  }
}

class TablesNotifier extends StateNotifier<TablesState> {
  final TablesRepository _repository;
  final String _branchId;
  final CancelToken _cancelToken;

  TablesNotifier(this._repository, this._branchId, this._cancelToken)
    : super(const TablesState()) {
    if (_branchId.isNotEmpty) {
      loadTables();
    }
  }

  Future<void> loadTables({
    String? sectionId,
    bool forceRefresh = false,
  }) async {
    if (state.isLoading) return;
    if (state.tablesById.isNotEmpty && !forceRefresh && sectionId == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTablesPaginated(
      branchId: _branchId,
      cancelToken: _cancelToken,
      sectionId: sectionId,
    );

    if (result is Success<List<RestaurantTableDto>>) {
      final newTables = forceRefresh
          ? <String, RestaurantTableDto>{}
          : Map<String, RestaurantTableDto>.from(state.tablesById);
      for (final table in result.value) {
        newTables[table.id] = table;
      }
      state = state.copyWith(isLoading: false, tablesById: newTables);
    } else if (result is Failure<List<RestaurantTableDto>>) {
      state = state.copyWith(isLoading: false, error: result.error.message);
    }
  }

  Future<Result<RestaurantTableDto>> createTable(
    RestaurantTableDto table,
  ) async {
    final result = await _repository.createTableEntity(
      table,
      branchId: _branchId,
    );

    if (result is Success<RestaurantTableDto>) {
      final newTables = Map<String, RestaurantTableDto>.from(state.tablesById);
      newTables[result.value.id] = result.value;
      state = state.copyWith(tablesById: newTables);
    }

    return result;
  }

  Future<Result<RestaurantTableDto>> updateTable(
    RestaurantTableDto table,
  ) async {
    final result = await _repository.updateTableEntity(
      table,
      branchId: _branchId,
    );

    if (result is Success<RestaurantTableDto>) {
      final newTables = Map<String, RestaurantTableDto>.from(state.tablesById);
      newTables[result.value.id] = result.value;
      state = state.copyWith(tablesById: newTables);
    } else if (result is Failure<RestaurantTableDto>) {
      if (result.error.code == ApiErrorCode.conflict) {
        await loadTables(forceRefresh: true);
      }
    }

    return result;
  }

  Future<Result<void>> deleteTable(String tableId) async {
    final table = state.tablesById[tableId];
    if (table == null) return Failure(ApiFailure('Table not found locally'));

    final result = await _repository.deleteTableEntity(
      tableId,
      table.versionNum,
      branchId: _branchId,
    );

    if (result is Success<void>) {
      final newTables = Map<String, RestaurantTableDto>.from(state.tablesById);
      newTables.remove(tableId);
      state = state.copyWith(tablesById: newTables);
    } else if (result is Failure<void>) {
      if (result.error.code == ApiErrorCode.conflict) {
        await loadTables(forceRefresh: true);
      }
    }

    return result;
  }

  /// Realtime Hook
  void reconcileRemoteTableUpdate(RestaurantTableDto remoteTable) {
    final newTables = Map<String, RestaurantTableDto>.from(state.tablesById);
    if (remoteTable.deletedAt != null) {
      newTables.remove(remoteTable.id);
    } else {
      newTables[remoteTable.id] = remoteTable;
    }
    state = state.copyWith(tablesById: newTables);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final tablesProvider = StateNotifierProvider<TablesNotifier, TablesState>((
  ref,
) {
  final repo = ref.watch(tablesRepositoryProvider);
  final currentBranch = ref.watch(currentBranchProvider).value;
  final cancelToken = ref.watch(branchCancellationServiceProvider).token;
  return TablesNotifier(repo, currentBranch?.id ?? '', cancelToken);
});

// Selector for rendering tables by section abstracting visual layout
final sectionTablesProvider = Provider.family<List<RestaurantTableDto>, String>(
  (ref, sectionId) {
    final state = ref.watch(tablesProvider);
    return state.tablesById.values
        .where((t) => t.sectionId == sectionId)
        .toList();
  },
);
