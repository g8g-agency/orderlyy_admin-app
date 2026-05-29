import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/dtos/runtime_event_dto.dart';
import '../../data/repositories/runtime_observability_repository.dart';

class RuntimeEventStreamState {
  final List<RuntimeEventDto> events;
  final bool isConnected;
  final String? error;

  RuntimeEventStreamState({
    this.events = const [],
    this.isConnected = false,
    this.error,
  });

  RuntimeEventStreamState copyWith({
    List<RuntimeEventDto>? events,
    bool? isConnected,
    String? error,
  }) {
    return RuntimeEventStreamState(
      events: events ?? this.events,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

final runtimeEventStreamProvider =
    StateNotifierProvider<RuntimeEventStreamNotifier, RuntimeEventStreamState>((
      ref,
    ) {
      final repository = ref.watch(runtimeObservabilityRepositoryProvider);
      return RuntimeEventStreamNotifier(repository);
    });

class RuntimeEventStreamNotifier
    extends StateNotifier<RuntimeEventStreamState> {
  final RuntimeObservabilityRepository _repository;
  final int _maxBufferSize = 1000;

  RuntimeEventStreamNotifier(this._repository)
    : super(RuntimeEventStreamState()) {
    _initStream();
  }

  void _initStream() {
    state = state.copyWith(isConnected: true, error: null);

    _repository.streamRuntimeEvents().listen(
      (event) {
        final newEvents = List<RuntimeEventDto>.from(state.events)..add(event);
        if (newEvents.length > _maxBufferSize) {
          newEvents.removeRange(0, newEvents.length - _maxBufferSize);
        }
        state = state.copyWith(events: newEvents);
      },
      onError: (e) {
        state = state.copyWith(isConnected: false, error: e.toString());
      },
      onDone: () {
        state = state.copyWith(isConnected: false);
      },
    );
  }

  void clearBuffer() {
    state = state.copyWith(events: []);
  }
}
