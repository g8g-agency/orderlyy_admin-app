import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/modifier_dto.dart';
import '../data/repositories/modifier_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Modifier State ────────────────────────────────────────────────────────────
class ModifierState {
  final bool isLoading;
  final String? error;

  // Normalized Maps
  final Map<String, ModifierGroupDto> groupsById;
  final Map<String, ModifierItemDto> itemsById;

  const ModifierState({
    this.isLoading = false,
    this.error,
    this.groupsById = const {},
    this.itemsById = const {},
  });

  ModifierState copyWith({
    bool? isLoading,
    String? error,
    Map<String, ModifierGroupDto>? groupsById,
    Map<String, ModifierItemDto>? itemsById,
  }) {
    return ModifierState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // intentional overwrite
      groupsById: groupsById ?? this.groupsById,
      itemsById: itemsById ?? this.itemsById,
    );
  }
}

// ── Modifier Notifier ─────────────────────────────────────────────────────────
class ModifierNotifier extends StateNotifier<ModifierState> {
  final ModifierRepository _repository;

  ModifierNotifier(this._repository) : super(const ModifierState());

  Future<void> loadGroups({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.groupsById.isNotEmpty && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getModifierGroups();

    if (result is Success<List<ModifierGroupDto>>) {
      final newGroups = forceRefresh ? <String, ModifierGroupDto>{} : Map<String, ModifierGroupDto>.from(state.groupsById);
      for (final group in result.data) {
        newGroups[group.id] = group;
      }
      state = state.copyWith(isLoading: false, groupsById: newGroups);
    } else if (result is Failure<List<ModifierGroupDto>>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  Future<void> loadItemsForGroup(String groupId, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getModifierItems(groupId);

    if (result is Success<List<ModifierItemDto>>) {
      final newItems = forceRefresh ? <String, ModifierItemDto>{} : Map<String, ModifierItemDto>.from(state.itemsById);
      for (final item in result.data) {
        newItems[item.id] = item;
      }
      state = state.copyWith(isLoading: false, itemsById: newItems);
    } else if (result is Failure<List<ModifierItemDto>>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  // GROUP CRUD
  Future<Result<ModifierGroupDto>> createGroup(ModifierGroupDto group) async {
    final result = await _repository.createModifierGroup(group);

    if (result is Success<ModifierGroupDto>) {
      final newGroups = Map<String, ModifierGroupDto>.from(state.groupsById);
      newGroups[result.data.id] = result.data;
      state = state.copyWith(groupsById: newGroups);
    }

    return result;
  }

  Future<Result<ModifierGroupDto>> updateGroup(ModifierGroupDto group) async {
    final result = await _repository.updateModifierGroup(group);

    if (result is Success<ModifierGroupDto>) {
      final newGroups = Map<String, ModifierGroupDto>.from(state.groupsById);
      newGroups[result.data.id] = result.data;
      state = state.copyWith(groupsById: newGroups);
    } else if (result is Failure<ModifierGroupDto>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadGroups(forceRefresh: true);
      }
    }

    return result;
  }

  Future<Result<void>> deleteGroup(String groupId) async {
    final group = state.groupsById[groupId];
    if (group == null) return Failure(ApiFailure('Group not found locally'));

    final result = await _repository.deleteModifierGroup(groupId, group.versionNum);

    if (result is Success<void>) {
      final newGroups = Map<String, ModifierGroupDto>.from(state.groupsById);
      newGroups.remove(groupId);
      state = state.copyWith(groupsById: newGroups);
    } else if (result is Failure<void>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadGroups(forceRefresh: true);
      }
    }

    return result;
  }

  // ITEM CRUD
  Future<Result<ModifierItemDto>> createItem(ModifierItemDto item) async {
    final result = await _repository.createModifierItem(item);

    if (result is Success<ModifierItemDto>) {
      final newItems = Map<String, ModifierItemDto>.from(state.itemsById);
      newItems[result.data.id] = result.data;
      state = state.copyWith(itemsById: newItems);
    }

    return result;
  }

  Future<Result<ModifierItemDto>> updateItem(ModifierItemDto item) async {
    final result = await _repository.updateModifierItem(item);

    if (result is Success<ModifierItemDto>) {
      final newItems = Map<String, ModifierItemDto>.from(state.itemsById);
      newItems[result.data.id] = result.data;
      state = state.copyWith(itemsById: newItems);
    } else if (result is Failure<ModifierItemDto>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadItemsForGroup(item.groupId, forceRefresh: true);
      }
    }

    return result;
  }

  Future<Result<void>> deleteItem(String itemId) async {
    final item = state.itemsById[itemId];
    if (item == null) return Failure(ApiFailure('Item not found locally'));

    final result = await _repository.deleteModifierItem(itemId, item.versionNum);

    if (result is Success<void>) {
      final newItems = Map<String, ModifierItemDto>.from(state.itemsById);
      newItems.remove(itemId);
      state = state.copyWith(itemsById: newItems);
    } else if (result is Failure<void>) {
      if (result.failure.code == ApiErrorCode.conflict) {
        await loadItemsForGroup(item.groupId, forceRefresh: true);
      }
    }

    return result;
  }

  // REALTIME
  void reconcileRemoteGroupUpdate(ModifierGroupDto remoteGroup) {
    final newGroups = Map<String, ModifierGroupDto>.from(state.groupsById);
    if (remoteGroup.deletedAt != null) {
      newGroups.remove(remoteGroup.id);
    } else {
      newGroups[remoteGroup.id] = remoteGroup;
    }
    state = state.copyWith(groupsById: newGroups);
  }

  void reconcileRemoteItemUpdate(ModifierItemDto remoteItem) {
    final newItems = Map<String, ModifierItemDto>.from(state.itemsById);
    if (remoteItem.deletedAt != null) {
      newItems.remove(remoteItem.id);
    } else {
      newItems[remoteItem.id] = remoteItem;
    }
    state = state.copyWith(itemsById: newItems);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final modifierProvider = StateNotifierProvider<ModifierNotifier, ModifierState>((ref) {
  final repo = ref.watch(modifierRepositoryProvider);
  return ModifierNotifier(repo);
});

// Selectors
final modifierItemsByGroupProvider = Provider.family<List<ModifierItemDto>, String>((ref, groupId) {
  final state = ref.watch(modifierProvider);
  return state.itemsById.values.where((item) => item.groupId == groupId).toList();
});
