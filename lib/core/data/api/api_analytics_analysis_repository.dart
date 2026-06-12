import '../dtos/analytics_analysis_dto.dart';
import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

class ApiAnalyticsAnalysisRepository {
  final DioClient _dioClient;

  ApiAnalyticsAnalysisRepository(this._dioClient);

  Future<Result<AnalyticsAnalysisDto>> getAnalysis({
    required String branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.analytics}/analysis',
        queryParameters: {
          'branch_id': branchId,
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate.toIso8601String().split('T').first,
          'tz_offset_mins': DateTime.now().timeZoneOffset.inMinutes.toString(),
        },
      );

      if (response.data['success'] == true) {
        return Success(
          AnalyticsAnalysisDto.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      } else {
        final msg = response.data['error']?['message'] ?? 'Failed to fetch analysis';
        return Failure(ApiFailure(msg, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
