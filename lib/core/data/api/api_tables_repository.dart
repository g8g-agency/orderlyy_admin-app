import '../dtos/table_dto.dart';
import '../repositories/tables_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';
import 'package:dio/dio.dart';

class ApiTablesRepository implements TablesRepository {
  final DioClient _dioClient;

  ApiTablesRepository(this._dioClient);

  @override
  Future<Result<List<RestaurantTableDto>>> getTablesPaginated({
    required String branchId,
    CancelToken? cancelToken,
    String? sectionId,
    int page = 1,
    int limit = 200,
    bool includeDeleted = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'branch_id': branchId,
        'page': page,
        'limit': limit,
        'include_deleted': includeDeleted,
        'section_id': ?sectionId,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.tables,
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final tables = data
            .map(
              (json) =>
                  RestaurantTableDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success(tables);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to fetch tables';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<RestaurantTableDto>> createTableEntity(
    RestaurantTableDto table, {
    required String branchId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.tables,
        queryParameters: {'branch_id': branchId},
        data: table.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(RestaurantTableDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to create table';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<RestaurantTableDto>> updateTableEntity(
    RestaurantTableDto table, {
    required String branchId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.tables}/${table.id}',
        queryParameters: {'branch_id': branchId},
        data: table.toJson(),
      );

      if (response.data['success'] == true) {
        return Success(RestaurantTableDto.fromJson(response.data['data']));
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to update table';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTableEntity(
    String tableId,
    int currentVersion, {
    required String branchId,
  }) async {
    try {
      final response = await _dioClient.dio.delete(
        '${ApiConstants.tables}/$tableId',
        queryParameters: {'version_num': currentVersion, 'branch_id': branchId},
      );

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to delete table';
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
  Future<List<RestaurantTableDto>> getTables(String tenantId) =>
      throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto?> getTableById(String tableId) =>
      throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto> createTable(RestaurantTableDto table) =>
      throw UnimplementedError('Deprecated');

  @override
  Future<RestaurantTableDto> updateTableStatus(
    String tableId,
    TableStatus newStatus, {
    String? activeOrderId,
  }) => throw UnimplementedError('Deprecated');

  @override
  Future<void> deleteTable(String tableId) =>
      throw UnimplementedError('Deprecated');

  @override
  Stream<List<RestaurantTableDto>> watchTables(String tenantId) =>
      throw UnimplementedError('Deprecated');
}
