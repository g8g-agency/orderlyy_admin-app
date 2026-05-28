import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/menu_dto.dart';
import '../data/repositories/menu_items_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Menu Items State ──────────────────────────────────────────────────────────
class MenuItemsState {
  final bool isLoading;
  final String? error;
  // Normalized store: itemId -> MenuItemDto
  final Map<String, MenuItemDto> byId;
  final bool isInitialized;

  const MenuItemsState({
    this.isLoading = false,
    this.error,
    this.byId = const {},
    this.isInitialized = false,
  });

  MenuItemsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, MenuItemDto>? byId,
    bool? isInitialized,
  }) {
    return MenuItemsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // intentionally overwriting to allow clearing
      byId: byId ?? this.byId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // Derived Selectors
  List<MenuItemDto> getItemsForCategory(String categoryId) {
    return byId.values
        .where((item) => item.categoryId == categoryId && item.deletedAt == null)
        .toList();
  }
}

// ── Menu Items Notifier ───────────────────────────────────────────────────────
class MenuItemsNotifier extends StateNotifier<MenuItemsState> {
  final MenuItemsRepository _repository;

  MenuItemsNotifier(this._repository) : super(const MenuItemsState());

  /// Loads menu items. For scale, we rely on the repository's pagination logic.
  /// Here we aggregate pages into our normalized store.
  Future<void> loadMenuItems({String? categoryId, bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.isInitialized && !forceRefresh && categoryId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getMenuItems(categoryId: categoryId);

    if (result is Success<List<MenuItemDto>>) {
      final newById = forceRefresh ? <String, MenuItemDto>{} : Map<String, MenuItemDto>.from(state.byId);
      for (final item in result.data) {
        newById[item.id] = item;
      }
      state = state.copyWith(
        isLoading: false,
        byId: newById,
        isInitialized: true,
      );
    } else if (result is Failure<List<MenuItemDto>>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  Future<Result<MenuItemDto>> createMenuItem(MenuItemDto item) async {
    final result = await _repository.createMenuItem(item);
    
    if (result is Success<MenuItemDto>) {
      final newItem = result.data;
      final newById = Map<String, MenuItemDto>.from(state.byId);
      newById[newItem.id] = newItem;
      state = state.copyWith(byId: newById);
    }
    
    return result;
  }

  Future<Result<MenuItemDto>> updateMenuItem(MenuItemDto item) async {
    final result = await _repository.updateMenuItem(item);
    
    if (result is Success<MenuItemDto>) {
      final updatedItem = result.data;
      final newById = Map<String, MenuItemDto>.from(state.byId);
      newById[updatedItem.id] = updatedItem;
      state = state.copyWith(byId: newById);
    } else if (result is Failure<MenuItemDto>) {
      // Deterministic reload on OCC Conflict
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadMenuItems(forceRefresh: true);
      }
    }
    
    return result;
  }

  Future<Result<void>> deleteMenuItem(String itemId) async {
    final item = state.byId[itemId];
    if (item == null) return Failure(ApiFailure('Menu Item not found locally'));

    final result = await _repository.deleteMenuItem(itemId, item.versionNum);

    if (result is Success<void>) {
      final newById = Map<String, MenuItemDto>.from(state.byId);
      newById.remove(itemId);
      state = state.copyWith(byId: newById);
    } else if (result is Failure<void>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadMenuItems(forceRefresh: true);
      }
    }

    return result;
  }

  /// Realtime reconciliation method. Call this when a realtime event is received.
  void reconcileRemoteUpdate(MenuItemDto remoteItem) {
    final newById = Map<String, MenuItemDto>.from(state.byId);
    // Soft deleted items are removed from normalized local state
    // Real tracking happens in backend via deletedAt
    if (remoteItem.deletedAt != null) {
      newById.remove(remoteItem.id);
    } else {
      newById[remoteItem.id] = remoteItem;
    }
    state = state.copyWith(byId: newById);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final menuItemsProvider = StateNotifierProvider<MenuItemsNotifier, MenuItemsState>((ref) {
  final repo = ref.watch(menuItemsRepositoryProvider);
  return MenuItemsNotifier(repo);
});

// Selector for a specific category's items
final categoryItemsProvider = Provider.family<List<MenuItemDto>, String>((ref, categoryId) {
  final state = ref.watch(menuItemsProvider);
  return state.getItemsForCategory(categoryId);
});
