import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../dtos/analytics_dtos.dart';

class AnalyticsRepository {
  final DioClient _dio;

  AnalyticsRepository(this._dio);

  Future<DashboardAnalyticsDto> getDashboardAnalytics(String branchId) async {
    try {
      final response = await _dio.get(
        '/v1/admin/analytics/dashboard',
        queryParameters: {'branch_id': branchId},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return DashboardAnalyticsDto.fromJson(data);
      } else {
        throw Exception('Failed to load analytics data: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Network error fetching analytics: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching analytics: $e');
    }
  }
}
