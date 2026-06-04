import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/providers/restaurant_context_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/dtos/analytics_dtos.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AnalyticsRepository(dio);
});

final dashboardAnalyticsProvider = FutureProvider.autoDispose<DashboardAnalyticsDto>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final activeBranch = ref.watch(activeBranchProvider);
  
  if (activeBranch == null) {
    throw Exception('No active branch selected');
  }
  
  return await repository.getDashboardAnalytics(activeBranch.id);
});
