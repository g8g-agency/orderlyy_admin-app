import '../dtos/menu_dto.dart';
import '../repositories/categories_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiCategoriesRepository implements CategoriesRepository {
  final DioClient _dioClient;
  final String _tenantId;
  final String? _branchId;

  ApiCategoriesRepository(this._dioClient, this._tenantId, {String? branchId})
      : _branchId = branchId;

  @override
  Future<Result<List<MenuCategoryDto>>> getCategories({
    String? search,
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final String path;
      if (_branchId != null) {
        path = '${ApiConstants.categories(_tenantId)}/branch/$_branchId';
      } else {
        path = ApiConstants.categories(_tenantId);
      }

      final response = await _dioClient.get(
        path,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final dynamic rawData = response.data['data'];
        final List<dynamic> dataList;
        if (rawData is Map && rawData.containsKey('data')) {
          dataList = rawData['data'] as List<dynamic>? ?? [];
        } else if (rawData is List) {
          dataList = rawData;
        } else {
          dataList = [];
        }
        final categories = dataList
            .map(
              (json) => MenuCategoryDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(categories);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to fetch categories';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuCategoryDto>> createCategory(
    MenuCategoryDto category,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.categories(_tenantId),
        data: category.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(MenuCategoryDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to create category';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuCategoryDto>> updateCategory(
    MenuCategoryDto category,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.categories(_tenantId)}/${category.id}',
        data: category
            .toJson(), // version_num is sent to backend for OCC validation
      );

      if (response.data['success'] == true) {
        return Success(MenuCategoryDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to update category';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCategory(
    String categoryId,
    int currentVersion,
  ) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.categories(_tenantId)}/$categoryId',
        data: {
          'version_num':
              currentVersion, // Backend expects version_num for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to delete category';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setCategoryVisibility({
    required String categoryId,
    required String branchId,
    required bool isVisible,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.categories(_tenantId)}/$categoryId/visibility',
        data: {
          'branch_id': branchId,
          'is_visible': isVisible,
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to update visibility';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
