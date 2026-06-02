import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/auth/bootstrap_provider.dart';
import '../../../core/auth/app_auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return DashboardRepository(dio);
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<void> dismissQrBanner() async {
    try {
      final response = await _dio.patch('/v1/admin/dashboard/dismiss-qr-banner');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to dismiss QR banner');
      }
    } catch (e) {
      throw Exception('Network error while dismissing banner: $e');
    }
  }
}
