// ── Menu Providers ────────────────────────────────────────────────────────────
// All menu data access goes through these providers.
// Screens MUST NOT import supabase_flutter or call Supabase.instance.client.
//
// Data flow:
//   MenuRepository (interface)
//     └─ MockMenuRepository        (kUseMockRepositories = true)
//     └─ SupabaseMenuRepository    (future, kUseMockRepositories = false)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/menu_dto.dart';
import 'repository_providers.dart';

import '../auth/app_auth_provider.dart';

// ── Menu items stream ─────────────────────────────────────────────────────────
// Emits every time the underlying repository pushes an update.
@Deprecated('Use menuItemsProvider and ApiMenuItemsRepository instead')
final menuItemsStreamProvider = StreamProvider<List<MenuItemDto>>((ref) async* {
  final ctx = ref.watch(appContextProvider);
  if (ctx == null) {
    yield [];
    return;
  }
  final tenantId = ctx.tenant.id;

  final repo = ref.watch(menuRepositoryProvider);
  yield* repo.watchMenuItems(tenantId);
});

// ── Toggle availability ───────────────────────────────────────────────────────
@Deprecated('Use updateMenuItem in menuItemsProvider instead')
final toggleMenuItemAvailabilityProvider =
    Provider<Future<void> Function(String itemId, bool isAvailable)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (itemId, isAvailable) async =>
          repo.toggleItemAvailability(itemId, isAvailable);
    });

// ── Create menu item ──────────────────────────────────────────────────────────
@Deprecated('Use createMenuItem in menuItemsProvider instead')
final createMenuItemProvider =
    Provider<Future<MenuItemDto> Function(MenuItemDto item)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (item) async => repo.createMenuItem(item);
    });

// ── Update menu item ──────────────────────────────────────────────────────────
@Deprecated('Use updateMenuItem in menuItemsProvider instead')
final updateMenuItemProvider =
    Provider<Future<MenuItemDto> Function(MenuItemDto item)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (item) async => repo.updateMenuItem(item);
    });

// ── Delete menu item ──────────────────────────────────────────────────────────
@Deprecated('Use deleteMenuItem in menuItemsProvider instead')
final deleteMenuItemProvider = Provider<Future<void> Function(String itemId)>((
  ref,
) {
  final repo = ref.read(menuRepositoryProvider);
  return (itemId) async => repo.deleteMenuItem(itemId);
});

// ── Delete all menu items ─────────────────────────────────────────────────────
final deleteAllMenuItemsProvider = Provider<Future<void> Function(String tenantId)>((
  ref,
) {
  final repo = ref.read(menuRepositoryProvider);
  return (tenantId) async => repo.deleteAllMenuItems(tenantId);
});

// ── Menu categories ───────────────────────────────────────────────────────────
@Deprecated('Use createCategory in categoriesProvider instead')
final createMenuCategoryProvider =
    Provider<Future<MenuCategoryDto> Function(MenuCategoryDto category)>((ref) {
      final repo = ref.read(menuRepositoryProvider);
      return (category) async => repo.createCategory(category);
    });

@Deprecated('Use categoriesProvider and ApiCategoriesRepository instead')
final menuCategoriesFutureProvider = FutureProvider<List<MenuCategoryDto>>((
  ref,
) async {
  final ctx = ref.watch(appContextProvider);
  if (ctx == null) {
    return [];
  }
  final tenantId = ctx.tenant.id;
  final repo = ref.watch(menuRepositoryProvider);
  return repo.getCategories(tenantId);
});

