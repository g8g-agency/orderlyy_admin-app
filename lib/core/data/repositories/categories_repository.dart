import '../dtos/menu_dto.dart';
import '../../network/api_exception.dart';

abstract class CategoriesRepository {
  /// Fetches a paginated/filtered list of categories from the backend.
  /// Pagination and search are driven completely by the server.
  Future<Result<List<MenuCategoryDto>>> getCategories({
    String? search,
    int page = 1,
    int limit = 100, // Fetch up to 100 per page to build trees efficiently
    bool includeDeleted = false,
  });

  /// Creates a new category. The backend handles `id`, `path`, and `depth` generation.
  Future<Result<MenuCategoryDto>> createCategory(MenuCategoryDto category);

  /// Updates a category. Mandatory OCC checking using `version_num`.
  Future<Result<MenuCategoryDto>> updateCategory(MenuCategoryDto category);

  /// Soft-deletes a category. Backend updates `deleted_at`.
  Future<Result<void>> deleteCategory(String categoryId, int currentVersion);

  /// Sets visibility of a category for a specific branch.
  Future<Result<void>> setCategoryVisibility({
    required String categoryId,
    required String branchId,
    required bool isVisible,
  });
}
