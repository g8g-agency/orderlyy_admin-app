import '../dtos/modifier_dto.dart';
import '../repositories/modifier_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiModifierRepository implements ModifierRepository {
  final DioClient _dioClient;

  ApiModifierRepository(this._dioClient);

  @override
  Future<Result<List<ModifierGroupDto>>> getModifierGroups({
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final response = await _dioClient.get(
        ApiConstants.modifiers,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final groups = data
            .map(
              (json) => ModifierGroupDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(groups);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch modifier groups';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ModifierItemDto>>> getModifierItems(
    String groupId, {
    int page = 1,
    int limit = 100,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'group_id': groupId,
        'page': page,
        'limit': limit,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final response = await _dioClient.get(
        '${ApiConstants.modifiers}/items',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final items = data
            .map(
              (json) => ModifierItemDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(items);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to fetch modifier items';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  // GROUP CRUD
  @override
  Future<Result<ModifierGroupDto>> createModifierGroup(
    ModifierGroupDto group,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.modifiers,
        data: group.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(ModifierGroupDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to create modifier group';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<ModifierGroupDto>> updateModifierGroup(
    ModifierGroupDto group,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.modifiers}/${group.id}',
        data: group.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(ModifierGroupDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to update modifier group';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteModifierGroup(
    String groupId,
    int currentVersion,
  ) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.modifiers}/$groupId',
        data: {
          'version_num':
              currentVersion, // Explicit OCC boundary for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to delete modifier group';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  // ITEM CRUD
  @override
  Future<Result<ModifierItemDto>> createModifierItem(
    ModifierItemDto item,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.modifiers}/items',
        data: item.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(ModifierItemDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to create modifier item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<ModifierItemDto>> updateModifierItem(
    ModifierItemDto item,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.modifiers}/items/${item.id}',
        data: item.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(ModifierItemDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to update modifier item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteModifierItem(
    String itemId,
    int currentVersion,
  ) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.modifiers}/items/$itemId',
        data: {
          'version_num':
              currentVersion, // Explicit OCC boundary for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ??
            'Failed to delete modifier item';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
