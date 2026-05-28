import '../dtos/restaurant_context_dto.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

abstract class RestaurantContextRepository {
  Future<Result<RestaurantContextDto>> fetchContext({String? branchId});
}

class ApiRestaurantContextRepository implements RestaurantContextRepository {
  final DioClient _dioClient;

  ApiRestaurantContextRepository(this._dioClient);

  @override
  Future<Result<RestaurantContextDto>> fetchContext({String? branchId}) async {
    try {
      final queryParams = branchId != null ? {'branchId': branchId} : null;
      
      final response = await _dioClient.get(
        ApiConstants.restaurantContext,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        try {
          final contextDto = RestaurantContextDto.fromJson(data);
          return Success(contextDto);
        } on FormatException catch (e) {
          return Failure(ApiFailure('Invalid context payload: ${e.message}', ApiErrorCode.validationError));
        }
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to fetch restaurant context';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
