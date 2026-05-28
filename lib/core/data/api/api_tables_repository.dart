import '../dtos/table_dto.dart';
import '../repositories/tables_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiTablesRepository implements TablesRepository {
  final DioClient _dioClient;

  ApiTablesRepository(this._dioClient);

  @override
  Future<Result<List<RestaurantTableDto>>> getTablesPaginated({
    String? sectionId,
    int page = 1,
    int limit = 200,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (sectionId != null) 'section_id': sectionId,
        if (includeDeleted) 'include_deleted': 'true',
      };

      final response = await _dioClient.get(
        ApiConstants.tables,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final tables = data
            .map((json) => RestaurantTableDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(tables);
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to fetch tables';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<RestaurantTableDto>> createTableEntity(RestaurantTableDto table) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.tables,
        data: table.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(RestaurantTableDto.fromJson(response.data['data']));
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to create table';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<RestaurantTableDto>> updateTableEntity(RestaurantTableDto table) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.tables}/${table.id}',
        data: table.toJson(), // version_num sent for OCC
      );

      if (response.data['success'] == true) {
        return Success(RestaurantTableDto.fromJson(response.data['data']));
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to update table';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTableEntity(String tableId, int currentVersion) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.tables}/$tableId',
        data: {
          'version_num': currentVersion, // Explicit OCC boundary for safe deletion
        },
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to delete table';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  // ── Deprecated Methods ──────────────────────────────────────────────────────
  
  @override
  Future<List<RestaurantTableDto>> getTables(String tenantId) => throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto?> getTableById(String tableId) => throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto> createTable(RestaurantTableDto table) => throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto> updateTableStatus(String tableId, TableStatus newStatus, {String? activeOrderId}) => throw UnimplementedError('Deprecated');

  @override
  Future<void> deleteTable(String tableId) => throw UnimplementedError('Deprecated');

  @override
  Stream<List<RestaurantTableDto>> watchTables(String tenantId) => throw UnimplementedError('Deprecated');
}
