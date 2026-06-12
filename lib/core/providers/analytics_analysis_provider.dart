import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dtos/analytics_analysis_dto.dart';
import '../data/api/api_analytics_analysis_repository.dart';
import '../network/api_exception.dart';
import '../network/network_providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class AnalyticsAnalysisState {
  final bool isLoading;
  final String? error;
  final AnalyticsAnalysisDto? data;

  const AnalyticsAnalysisState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  AnalyticsAnalysisState copyWith({
    bool? isLoading,
    String? error,
    AnalyticsAnalysisDto? data,
  }) {
    return AnalyticsAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AnalyticsAnalysisNotifier extends StateNotifier<AnalyticsAnalysisState> {
  final ApiAnalyticsAnalysisRepository _repo;

  AnalyticsAnalysisNotifier(this._repo) : super(const AnalyticsAnalysisState());

  Future<void> fetch({
    required String branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repo.getAnalysis(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result is Success<AnalyticsAnalysisDto>) {
        state = state.copyWith(isLoading: false, data: result.value);
      } else if (result is Failure<AnalyticsAnalysisDto>) {
        state = state.copyWith(isLoading: false, error: result.error.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final analyticsAnalysisRepositoryProvider = Provider<ApiAnalyticsAnalysisRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiAnalyticsAnalysisRepository(dio);
});

final analyticsAnalysisProvider =
    StateNotifierProvider<AnalyticsAnalysisNotifier, AnalyticsAnalysisState>((ref) {
  final repo = ref.watch(analyticsAnalysisRepositoryProvider);
  return AnalyticsAnalysisNotifier(repo);
});
