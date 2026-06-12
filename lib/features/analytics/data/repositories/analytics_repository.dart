import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../dtos/analytics_dtos.dart';

class AnalyticsRepository {
  final DioClient _dio;

  AnalyticsRepository(this._dio);

  Future<DashboardAnalyticsDto> getDashboardAnalytics(String branchId) async {
    try {
      final response = await _dio.get(
        '/api/v1/analytics/daily',  // ✅ correct endpoint
        queryParameters: {
          'branch_id': branchId,
          'date': DateTime.now().toIso8601String().split('T').first,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return DashboardAnalyticsDto.fromBackend(data);
      } else {
        throw Exception('Failed to load analytics: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Network error fetching analytics: ${e.message}');
    }
  }
}
