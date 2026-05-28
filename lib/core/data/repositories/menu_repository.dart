// ── MenuRepository interface ───────────────────────────────────────────────────
// The UI layer ONLY depends on this contract.
// Implementations: MockMenuRepository (dev) | SupabaseMenuRepository (prod)

import '../dtos/menu_dto.dart';

abstract class MenuRepository {
  // ── Categories ────────────────────────────────────────────────────────────
  @Deprecated('Use CategoriesRepository instead')
  Future<List<MenuCategoryDto>> getCategories(String tenantId);

  @Deprecated('Use CategoriesRepository instead')
  Future<MenuCategoryDto> createCategory(MenuCategoryDto category);

  @Deprecated('Use CategoriesRepository instead')
  Future<MenuCategoryDto> updateCategory(MenuCategoryDto category);

  @Deprecated('Use CategoriesRepository instead')
  Future<void> deleteCategory(String categoryId);

  // ── Menu items ────────────────────────────────────────────────────────────
  @Deprecated('Use MenuItemsRepository instead')
  Future<List<MenuItemDto>> getMenuItems(String tenantId, {String? categoryId});

  @Deprecated('Use MenuItemsRepository instead')
  Future<MenuItemDto> createMenuItem(MenuItemDto item);

  @Deprecated('Use MenuItemsRepository instead')
  Future<MenuItemDto> updateMenuItem(MenuItemDto item);

  @Deprecated('Use MenuItemsRepository instead')
  Future<void> deleteMenuItem(String itemId);

  @Deprecated('Use MenuItemsRepository instead')
  Future<void> toggleItemAvailability(String itemId, bool isAvailable);

  // ── Realtime-like stream (fake events in mock) ────────────────────────────
  Stream<List<MenuItemDto>> watchMenuItems(String tenantId);
}
