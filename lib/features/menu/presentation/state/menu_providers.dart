// lib/features/menu/presentation/state/menu_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/sync_state.dart';
import '../../../../core/utils/logger.dart';
import '../../../orders/domain/entities/menu_product.dart' as orders_entities;
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_snapshot.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../runtime/snapshot_migration.dart';

final menuSnapshotRepositoryProvider = Provider<MenuRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final cacheBox = ref.watch(apiCacheBoxProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final talker = ref.watch(talkerProvider);
  return MenuRepositoryImpl(
    dioClient: dioClient,
    apiCacheBox: cacheBox,
    networkInfo: networkInfo,
    talker: talker,
  );
});

// Core Providers
final branchIdProvider = Provider<String>((ref) {
  return 'branch_1';
});

final menuCacheProvider = Provider<MenuRepository>((ref) {
  return ref.watch(menuSnapshotRepositoryProvider);
});

class MenuSnapshotNotifier extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final MenuRepository _repository;
  final Ref _ref;
  final Talker _talker;
  bool _isOfflineCache = false;
  int _lastOverlayRevision = 0;

  MenuSnapshotNotifier(this._repository, this._ref, this._talker)
    : super(const AsyncValue.loading()) {
    // Automatically load when initialized
    loadMenu();
  }

  bool get isOfflineCache => _isOfflineCache;

  Future<void> loadMenu({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final branchId = _ref.read(branchIdProvider);

      // Perform schema verification and migration before fetching/serving
      final migration = SnapshotMigration(
        repository: _repository,
        talker: _talker,
      );
      await migration.verifyAndMigrate(branchId);

      final isConnected = await _ref.read(networkInfoProvider).isConnected;
      _isOfflineCache = !isConnected;



      await _fetch(branchId: branchId, forceRefresh: forceRefresh);
    } catch (e, stack) {
      _talker.error('[MenuSnapshotNotifier] Failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _fetch({
    required String branchId,
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await _repository.getMenuSnapshot(
        branchId: branchId,
        forceRefresh: forceRefresh,
      );
      state = AsyncValue.data(snapshot);
    } catch (e, stack) {
      _talker.error('[MenuSnapshotNotifier] Fetch failed: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void reconcileAvailability({
    required Map<String, bool> authoritativeAvailability,
    required int revision,
  }) {
    if (revision <= _lastOverlayRevision) {
      _talker.info(
        '[MenuNotifier] Ignored stale overlay revision $revision (last=$_lastOverlayRevision).',
      );
      return;
    }

    state.whenData((snapshot) {
      final updatedItems = snapshot.items.map((item) {
        return item.copyWith(
          isAvailable: authoritativeAvailability[item.id] ?? false,
        );
      }).toList();

      state = AsyncValue.data(
        MenuSnapshot(
          categories: snapshot.categories,
          items: updatedItems,
          modifierGroups: snapshot.modifierGroups,
          taxConfig: snapshot.taxConfig,
        ),
      );

      _lastOverlayRevision = revision;
    });
  }
}

final menuSnapshotProvider =
    StateNotifierProvider<MenuSnapshotNotifier, AsyncValue<MenuSnapshot>>((
      ref,
    ) {
      final repository = ref.watch(menuSnapshotRepositoryProvider);
      final talker = ref.watch(talkerProvider);
      // Re-run if branch changes
      ref.watch(branchIdProvider);
      return MenuSnapshotNotifier(repository, ref, talker);
    });

class MenuAvailabilityNotifier extends StateNotifier<Map<String, bool>> {
  MenuAvailabilityNotifier() : super(const {});

  void updateAvailability(Map<String, bool> availabilityMap) {
    state = {...state, ...availabilityMap};
  }
}

final menuAvailabilityProvider =
    StateNotifierProvider<MenuAvailabilityNotifier, Map<String, bool>>((ref) {
      return MenuAvailabilityNotifier();
    });

// Derived Providers
final availableItemsProvider = Provider<List<MenuItem>>((ref) {
  final projection = ref.watch(menuSnapshotProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.items.where((i) => i.isAvailable).toList(),
    orElse: () => const [],
  );
});

final branchMenuProvider = Provider<List<MenuItem>>((ref) {
  final projection = ref.watch(menuSnapshotProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.items,
    orElse: () => const [],
  );
});

final modifierGroupsProvider = Provider<List<ModifierGroup>>((ref) {
  final projection = ref.watch(menuSnapshotProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.modifierGroups,
    orElse: () => const [],
  );
});

final taxProjectionProvider = Provider<TaxConfig?>((ref) {
  final projection = ref.watch(menuSnapshotProvider);
  return projection.maybeWhen(
    data: (snapshot) => snapshot.taxConfig,
    orElse: () => null,
  );
});

class MenuStalenessInfo {
  final SyncState syncState;
  final DateTime? lastSyncTime;
  final double confidenceScore;

  const MenuStalenessInfo({
    required this.syncState,
    this.lastSyncTime,
    required this.confidenceScore,
  });
}

final staleMenuProvider = Provider<MenuStalenessInfo>((ref) {
  final snapshotState = ref.watch(menuSnapshotProvider);
  final isConnected =
      ref.watch(menuSnapshotProvider.notifier).isOfflineCache == false;

  final lastSync = snapshotState.maybeWhen(
    data: (s) => s.generatedAt ?? DateTime.now(),
    orElse: () => null,
  );

  if (!isConnected) {
    return MenuStalenessInfo(
      syncState: SyncState.degraded,
      lastSyncTime: lastSync,
      confidenceScore: 0.5,
    );
  }

  return MenuStalenessInfo(
    syncState: SyncState.fresh,
    lastSyncTime: lastSync ?? DateTime.now(),
    confidenceScore: 1.0,
  );
});

// Legacy compatibility providers
class LegacyMenuSnapshotNotifier
    extends StateNotifier<AsyncValue<MenuSnapshot>> {
  final Ref _ref;

  LegacyMenuSnapshotNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<AsyncValue<MenuSnapshot>>(menuSnapshotProvider, (
      previous,
      next,
    ) {
      state = next;
    }, fireImmediately: true);
  }

  bool get isOfflineCache {
    return _ref.read(menuSnapshotProvider.notifier).isOfflineCache;
  }

  Future<void> loadMenu({bool forceRefresh = false}) async {
    await _ref
        .read(menuSnapshotProvider.notifier)
        .loadMenu(forceRefresh: forceRefresh);
  }

  Future<void> refresh() async {
    await _ref.read(menuSnapshotProvider.notifier).loadMenu(forceRefresh: true);
  }

  void updateAvailability(Map<String, bool> availabilityMap) {
    _ref
        .read(menuAvailabilityProvider.notifier)
        .updateAvailability(availabilityMap);
    state.whenData((snapshot) {
      final updatedItems = snapshot.items.map((item) {
        if (availabilityMap.containsKey(item.id)) {
          return item.copyWith(isAvailable: availabilityMap[item.id]!);
        }
        return item;
      }).toList();
      state = AsyncValue.data(
        MenuSnapshot(
          categories: snapshot.categories,
          items: updatedItems,
          modifierGroups: snapshot.modifierGroups,
          taxConfig: snapshot.taxConfig,
        ),
      );
    });
  }
}

final menuSnapshotNotifierProvider =
    StateNotifierProvider<LegacyMenuSnapshotNotifier, AsyncValue<MenuSnapshot>>(
      (ref) {
        return LegacyMenuSnapshotNotifier(ref);
      },
    );

final publicMenuProductsProvider = Provider<List<orders_entities.MenuProduct>>((
  ref,
) {
  final menuSnapshotAsync = ref.watch(menuSnapshotNotifierProvider);
  return menuSnapshotAsync.maybeWhen(
    data: (snapshot) => snapshot.toMenuProducts(),
    orElse: () => const [],
  );
});

final menuStalenessProvider = Provider<SyncState>((ref) {
  final staleness = ref.watch(staleMenuProvider);
  return staleness.syncState;
});

final menuAvailabilityPollingProvider = Provider.autoDispose<void>((ref) {
  // Supervisory only: no availability polling required for client sessions.
});

