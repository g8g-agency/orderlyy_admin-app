import '../dtos/menu_dto.dart';
import '../../network/api_exception.dart';

abstract class MenuItemsRepository {
  /// Fetches a paginated/filtered list of menu items from the backend.
  /// Enforces server-driven pagination and search.
  Future<Result<List<MenuItemDto>>> getMenuItems({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 50,
    bool includeDeleted = false,
  });

  /// Creates a new menu item. The backend generates `id`, `version_num`, `deleted_at`.
  Future<Result<MenuItemDto>> createMenuItem(MenuItemDto item);

  /// Updates a menu item. Mandatory OCC checking using `version_num`.
  Future<Result<MenuItemDto>> updateMenuItem(MenuItemDto item);

  /// Soft-deletes a menu item. Backend handles visibility changes and updates `deleted_at`.
  Future<Result<void>> deleteMenuItem(String itemId, int currentVersion);
}
