import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/dtos/runtime_event_dto.dart';
import '../../data/repositories/runtime_observability_repository.dart';
import '../../../../core/network/api_exception.dart';

class ReplayTraceState {
  final String runId;
  final List<RuntimeEventDto> events;
  final int totalCount;
  final bool isLoading;
  final String? error;

  ReplayTraceState({
    required this.runId,
    required this.events,
    required this.totalCount,
    this.isLoading = false,
    this.error,
  });

  ReplayTraceState copyWith({
    String? runId,
    List<RuntimeEventDto>? events,
    int? totalCount,
    bool? isLoading,
    String? error,
  }) {
    return ReplayTraceState(
      runId: runId ?? this.runId,
      events: events ?? this.events,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoricalReplayNotifier extends StateNotifier<ReplayTraceState> {
  final RuntimeObservabilityRepository _repository;
  static const int _pageSize = 50;

  HistoricalReplayNotifier(this._repository)
      : super(ReplayTraceState(runId: '', events: [], totalCount: 0));

  Future<void> loadRun(String runId) async {
    state = state.copyWith(runId: runId, isLoading: true, error: null, events: [], totalCount: 0);
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.runId.isEmpty || (state.events.isNotEmpty && state.events.length >= state.totalCount)) {
      return; // Nothing to load
    }

    state = state.copyWith(isLoading: true);

    final startIndex = state.events.length;
    final endIndex = startIndex + _pageSize;

    final result = await _repository.getReplayTraceWindow(
      state.runId,
      startIndex: startIndex,
      endIndex: endIndex,
      direction: 'asc',
    );

    if (result is Success<Map<String, dynamic>>) {
      final data = result.value;
      final rawEvents = data['trace'] as List<dynamic>? ?? [];
      final newEvents = rawEvents.map((e) => RuntimeEventDto.fromJson(e as Map<String, dynamic>)).toList();
      final total = data['total'] as int? ?? 0;

      state = state.copyWith(
        events: [...state.events, ...newEvents],
        totalCount: total,
        isLoading: false,
      );
    } else if (result is Failure<Map<String, dynamic>>) {
      state = state.copyWith(
        isLoading: false,
        error: result.error.message,
      );
    }
  }
}

final historicalReplayProvider = StateNotifierProvider<HistoricalReplayNotifier, ReplayTraceState>((ref) {
  final repo = ref.watch(runtimeObservabilityRepositoryProvider);
  return HistoricalReplayNotifier(repo);
});
