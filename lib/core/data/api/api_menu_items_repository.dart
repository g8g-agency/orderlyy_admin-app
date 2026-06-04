import '../dtos/menu_dto.dart';
import '../repositories/menu_items_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiMenuItemsRepository implements MenuItemsRepository {
  final DioClient _dioClient;
  final String _tenantId;

  ApiMenuItemsRepository(this._dioClient, this._tenantId);

  @override
  Future<Result<List<MenuItemDto>>> getMenuItems({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 50,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'category_id': ?categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final response = await _dioClient.get(
        ApiConstants.menuItems(_tenantId),
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
        final items = dataList
            .map((json) => MenuItemDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(items);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to fetch menu items';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemDto>> createMenuItem(MenuItemDto item) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.menuItems(_tenantId),
        data: item.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(MenuItemDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to create menu item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<MenuItemDto>> updateMenuItem(MenuItemDto item) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.menuItems(_tenantId)}/${item.id}',
        data: item.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(MenuItemDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to update menu item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMenuItem(String itemId, int currentVersion) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.menuItems(_tenantId)}/$itemId',
        data: {
          'version_num':
              currentVersion, // Explicit OCC boundary for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to delete menu item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
