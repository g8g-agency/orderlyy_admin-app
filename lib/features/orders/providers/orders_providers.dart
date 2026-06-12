import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/providers/restaurant_context_provider.dart';
import '../data/datasources/orders_api_datasource.dart';

final ordersApiDatasourceProvider = Provider<OrdersApiDatasource>((ref) {
  final supabase = Supabase.instance.client;
  final dio = ref.watch(dioClientProvider);
  return OrdersApiDatasource(supabase, dio);
});

// Stream of live orders for active branch
final liveOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final datasource = ref.watch(ordersApiDatasourceProvider);
  final activeBranch = ref.watch(activeBranchProvider);
  
  if (activeBranch == null) return Stream.value([]);
  return datasource.watchBranchOrders(activeBranch.id);
});
