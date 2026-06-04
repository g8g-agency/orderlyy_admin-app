import '../../network/dio_client.dart';
import '../../network/api_exception.dart';

class ApiMenuRecommendationsRepository {
  final DioClient _dioClient;
  final String _tenantId;

  ApiMenuRecommendationsRepository(this._dioClient, this._tenantId);

  Future<List<dynamic>> getRecommendations(String itemId) async {
    try {
      final response = await _dioClient.get(
        '/api/v1/tenants/$_tenantId/menu/items/$itemId/recommendations',
      );
      if (response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ??
            'Failed to load recommendations',
        code: ApiErrorCode.serverError,
      );
    } catch (e) {
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  Future<dynamic> addRecommendation(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/tenants/$_tenantId/menu/items/$itemId/recommendations',
        data: data,
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ??
            'Failed to add recommendation',
        code: ApiErrorCode.serverError,
      );
    } catch (e) {
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  Future<dynamic> updateRecommendation(
    String recId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.patch(
        '/api/v1/tenants/$_tenantId/menu/recommendations/$recId',
        data: data,
      );
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw ApiException(
        message:
            response.data['error']?['message'] ??
            'Failed to update recommendation',
        code: ApiErrorCode.serverError,
      );
    } catch (e) {
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }

  Future<void> deleteRecommendation(String recId) async {
    try {
      final response = await _dioClient.delete(
        '/api/v1/tenants/$_tenantId/menu/recommendations/$recId',
      );
      if (response.statusCode != 204 && response.data['success'] != true) {
        throw ApiException(
          message: response.data['error']?['message'] ?? 'Failed to delete',
          code: ApiErrorCode.serverError,
        );
      }
    } catch (e) {
      throw ApiException(message: e.toString(), code: ApiErrorCode.unknown);
    }
  }
}
