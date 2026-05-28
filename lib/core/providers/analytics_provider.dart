import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/analytics_dto.dart';
import '../data/repositories/analytics_repository.dart';
import '../network/api_exception.dart';
import 'repository_providers.dart';

// ── Analytics State ───────────────────────────────────────────────────────────
class AnalyticsState {
  final bool isLoading;
  final String? error;
  
  // Cache for daily summaries (Time-bounded projection)
  // Key format: "YYYY-MM-DD" or "YYYY-MM-DD_branchId"
  final Map<String, DailySummaryProjectionDto> dailySummaries;

  const AnalyticsState({
    this.isLoading = false,
    this.error,
    this.dailySummaries = const {},
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    Map<String, DailySummaryProjectionDto>? dailySummaries,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Intentional overwrite
      dailySummaries: dailySummaries ?? this.dailySummaries,
    );
  }
}

// ── Analytics Notifier ────────────────────────────────────────────────────────
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsNotifier(this._repository) : super(const AnalyticsState());

  String _getCacheKey(DateTime date, String? branchId) {
    final dateStr = date.toIso8601String().split('T').first;
    return branchId == null ? dateStr : '${dateStr}_$branchId';
  }

  /// Fetches a backend-resolved daily analytics projection.
  /// No local KPI math or raw dataset aggregations allowed.
  Future<void> fetchDailySummary({
    required DateTime date, 
    String? branchId, 
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(date, branchId);
    
    if (state.isLoading) return;
    if (state.dailySummaries.containsKey(cacheKey) && !forceRefresh) {
      // In production, we'd add explicit TTL checking here (e.g., refetch if generatedAt is > 5 min old)
      // For now, we respect forceRefresh.
      return; 
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getDailySummary(date: date, branchId: branchId);

    if (result is Success<DailySummaryProjectionDto>) {
      final newCache = Map<String, DailySummaryProjectionDto>.from(state.dailySummaries);
      newCache[cacheKey] = result.data;
      state = state.copyWith(isLoading: false, dailySummaries: newCache);
    } else if (result is Failure<DailySummaryProjectionDto>) {
      state = state.copyWith(isLoading: false, error: result.failure.message);
    }
  }

  /// Realtime hook. 
  /// Invalidates the projection for the current operational day to trigger a background fetch.
  /// Does NOT blindly push raw operational events into UI charts.
  void invalidateTodayProjection({String? branchId}) {
    final today = DateTime.now().toUtc();
    fetchDailySummary(date: today, branchId: branchId, forceRefresh: true);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return AnalyticsNotifier(repo);
});

// Selector for daily summary
final dailySummaryProvider = Provider.family<DailySummaryProjectionDto?, Map<String, dynamic>>((ref, params) {
  final state = ref.watch(analyticsProvider);
  final date = params['date'] as DateTime;
  final branchId = params['branchId'] as String?;
  
  final dateStr = date.toIso8601String().split('T').first;
  final cacheKey = branchId == null ? dateStr : '${dateStr}_$branchId';
  
  return state.dailySummaries[cacheKey];
});
