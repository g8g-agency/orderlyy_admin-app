import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DashboardRepository(dioClient);
});

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  Future<void> dismissQrBanner() async {
    try {
      final response = await _dioClient.patch(
        '/api/v1/admin/dashboard/dismiss-qr-banner',
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to dismiss QR banner');
      }
    } catch (e) {
      throw Exception('Network error while dismissing banner: $e');
    }
  }
}
