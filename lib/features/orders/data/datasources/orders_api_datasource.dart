import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/dio_client.dart';

class OrdersApiDatasource {
  final SupabaseClient _supabase;
  final DioClient _dio;

  OrdersApiDatasource(this._supabase, this._dio);

  // Fetch all active orders for branch via backend API
  Future<List<Map<String, dynamic>>> fetchBranchOrders(String branchId) async {
    final response = await _dio.get(
      '/api/v1/orders',
      queryParameters: {'branch_id': branchId},
    );
    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data['orders'] is List) {
        return List<Map<String, dynamic>>.from(data['orders']);
      }
    }
    return [];
  }

  // Realtime stream of orders for branch — same pattern as KDS
  Stream<List<Map<String, dynamic>>> watchBranchOrders(String branchId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    // Initial load
    fetchBranchOrders(branchId).then((orders) {
      if (!controller.isClosed) controller.add(orders);
    });

    // Realtime updates
    _supabase
      .channel('admin_orders_$branchId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'branch_id',
          value: branchId,
        ),
        callback: (payload) async {
          final orders = await fetchBranchOrders(branchId);
          if (!controller.isClosed) controller.add(orders);
        },
      )
      .subscribe();

    return controller.stream;
  }
}
