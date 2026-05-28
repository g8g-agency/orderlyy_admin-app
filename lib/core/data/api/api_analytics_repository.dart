import '../dtos/analytics_dto.dart';
import '../repositories/analytics_repository.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiAnalyticsRepository implements AnalyticsRepository {
  final DioClient _dioClient;

  ApiAnalyticsRepository(this._dioClient);

  @override
  Future<Result<DailySummaryProjectionDto>> getDailySummary({
    required DateTime date,
    String? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'date': date.toIso8601String().split('T').first,
        if (branchId != null) 'branch_id': branchId,
      };

      final response = await _dioClient.get(
        '${ApiConstants.analytics}/daily',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return Success(DailySummaryProjectionDto.fromJson(response.data['data']));
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to fetch daily summary';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DailySummaryProjectionDto>>> getAnalyticsRange({
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        if (branchId != null) 'branch_id': branchId,
      };

      final response = await _dioClient.get(
        '${ApiConstants.analytics}/range',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        final projections = data
            .map((json) => DailySummaryProjectionDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(projections);
      } else {
        final errorMessage = response.data['error']?['message'] ?? 'Failed to fetch analytics range';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
